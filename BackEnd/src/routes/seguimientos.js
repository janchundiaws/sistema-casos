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

module.exports = routerSegu;
