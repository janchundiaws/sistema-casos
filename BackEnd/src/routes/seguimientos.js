const express5 = require('express');
const routerSegu = express5.Router();
const { poolPromise: poolP4 } = require('../db');
const { authenticateToken: authMW2 } = require('../middleware/auth');

/**
 * @swagger
 * tags:
 *   name: Seguimientos
 *   description: Seguimientos de casos
 */

/**
 * @swagger
 * /api/seguimientos:
 *   post:
 *     tags: [Seguimientos]
 *     summary: Agrega un seguimiento a un caso
 *     description: Crea un nuevo seguimiento para un caso específico
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - id_caso
 *               - retroalimentacion
 *             properties:
 *               id_caso:
 *                 type: integer
 *                 example: 1
 *               retroalimentacion:
 *                 type: string
 *                 example: "Se realizó la inspección inicial del área afectada"
 *               estado:
 *                 type: string
 *                 enum: [Iniciado, "En proceso", Finalizado]
 *                 default: "En proceso"
 *     responses:
 *       200:
 *         description: Seguimiento creado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 id_seguimiento:
 *                   type: integer
 *                   example: 1
 *       401:
 *         description: Token de autenticación requerido
 *       500:
 *         description: Error interno del servidor
 */
routerSegu.post('/', authMW2, async (req, res) => {
  try {
    const { id_caso, retroalimentacion, estado } = req.body;
    const pool = await poolP4;
    const id_usuario = req.user.id_usuario;
    const result = await pool.request()
      .input('id_caso', id_caso)
      .input('id_usuario', id_usuario)
      .input('retro', retroalimentacion)
      .input('estado', estado || 'En proceso')
      .query(`INSERT INTO Seguimiento (id_caso, id_usuario, retroalimentacion, estado) VALUES (@id_caso, @id_usuario, @retro, @estado); SELECT SCOPE_IDENTITY() as id_seguimiento;`);

    // Optionally update Caso.estado
    await pool.request().input('id_caso', id_caso).input('estado', estado || 'En proceso').query('UPDATE Caso SET estado = @estado WHERE id_caso = @id_caso');

    res.json({ id_seguimiento: result.recordset[0].id_seguimiento });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error creando seguimiento', error: err.message });
  }
});

/**
 * @swagger
 * /api/seguimientos/{id}:
 *   put:
 *     tags: [Seguimientos]
 *     summary: Actualiza un seguimiento existente
 *     description: Permite modificar la retroalimentación y/o el estado de un seguimiento
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del seguimiento a actualizar
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               retroalimentacion:
 *                 type: string
 *               estado:
 *                 type: string
 *                 enum: [Iniciado, "En proceso", Finalizado]
 *     responses:
 *       200:
 *         description: Seguimiento actualizado exitosamente
 *       400:
 *         description: Datos inválidos
 *       404:
 *         description: Seguimiento no encontrado
 *       500:
 *         description: Error interno del servidor
 */
routerSegu.put('/:id', authMW2, async (req, res) => {
  try {
    const { id } = req.params;
    const { retroalimentacion, estado } = req.body;
    const pool = await poolP4;

    // Verificar que el seguimiento exista y obtener id_caso
    const segRes = await pool.request()
      .input('id', id)
      .query('SELECT id_caso FROM Seguimiento WHERE id_seguimiento = @id');

    if (!segRes.recordset.length) {
      return res.status(404).json({ message: 'Seguimiento no encontrado' });
    }

    // Construir actualización dinámica
    if (retroalimentacion == null && estado == null) {
      return res.status(400).json({ message: 'Nada que actualizar' });
    }

    const updates = [];
    if (retroalimentacion != null) updates.push('retroalimentacion = @retro');
    if (estado != null) updates.push('estado = @estado');

    await pool.request()
      .input('id', id)
      .input('retro', retroalimentacion ?? null)
      .input('estado', estado ?? null)
      .query(`UPDATE Seguimiento SET ${updates.join(', ')} WHERE id_seguimiento = @id`);

    // Si cambia estado, opcionalmente reflejar en Caso
    if (estado != null) {
      const id_caso = segRes.recordset[0].id_caso;
      await pool.request()
        .input('id_caso', id_caso)
        .input('estado', estado)
        .query('UPDATE Caso SET estado = @estado WHERE id_caso = @id_caso');
    }

    res.json({ message: 'Seguimiento actualizado' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error actualizando seguimiento', error: err.message });
  }
});

/**
 * @swagger
 * /api/seguimientos/{id}:
 *   delete:
 *     tags: [Seguimientos]
 *     summary: Elimina un seguimiento
 *     description: Elimina un seguimiento por su ID
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del seguimiento a eliminar
 *     responses:
 *       200:
 *         description: Seguimiento eliminado exitosamente
 *       404:
 *         description: Seguimiento no encontrado
 *       500:
 *         description: Error interno del servidor
 */
routerSegu.delete('/:id', authMW2, async (req, res) => {
  try {
    const { id } = req.params;
    const pool = await poolP4;

    const exists = await pool.request()
      .input('id', id)
      .query('SELECT 1 FROM Seguimiento WHERE id_seguimiento = @id');

    if (!exists.recordset.length) {
      return res.status(404).json({ message: 'Seguimiento no encontrado' });
    }

    await pool.request()
      .input('id', id)
      .query('DELETE FROM Seguimiento WHERE id_seguimiento = @id');

    res.json({ message: 'Seguimiento eliminado' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error eliminando seguimiento', error: err.message });
  }
});

module.exports = routerSegu;
