const express4 = require('express');
const routerCasos = express4.Router();
const { poolPromise: poolP3 } = require('../db');
const { authenticateToken: authMW } = require('../middleware/auth');

/**
 * @swagger
 * tags:
 *   name: Casos
 *   description: Gestión de casos
 */

/**
 * @swagger
 * /api/casos:
 *   get:
 *     tags: [Casos]
 *     summary: Obtiene la lista de todos los casos
 *     description: Retorna un array con todos los casos del sistema
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: estado
 *         schema:
 *           type: string
 *           enum: [Iniciado, "En proceso", Finalizado]
 *         description: Filtrar por estado del caso
 *       - in: query
 *         name: id_area
 *         schema:
 *           type: integer
 *         description: Filtrar por área asignada
 *     responses:
 *       200:
 *         description: Lista de casos obtenida exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id_caso:
 *                     type: integer
 *                   titulo:
 *                     type: string
 *                   descripcion:
 *                     type: string
 *                   tipo:
 *                     type: string
 *                   estado:
 *                     type: string
 *                   fecha_creacion:
 *                     type: string
 *                     format: date-time
 *                   areas_asignadas:
 *                     type: string
 *                     example: "Recursos Humanos, Seguridad"
 *                   area_usuario:
 *                     type: string
 *                     example: "Recursos Humanos"
 *                     description: Área a la que pertenece el usuario autenticado
 *                   descripcion_area_usuario:
 *                     type: string
 *                     example: "Área encargada de gestión de personal"
 *                     description: Descripción del área del usuario autenticado
 *       401:
 *         description: Token de autenticación requerido
 *       500:
 *         description: Error interno del servidor
 */
routerCasos.get('/', authMW, async (req, res) => {
  try {
    const { estado, id_area } = req.query;
    const pool = await poolP3;
    
    // Obtener información del usuario autenticado
    const userId = req.user.id_usuario;
    const userQuery = `
      SELECT u.id_usuario, u.id_area, a.nombre as area_usuario, a.descripcion as descripcion_area_usuario
      FROM Usuario u
      LEFT JOIN Area a ON u.id_area = a.id_area
      WHERE u.id_usuario = @userId
    `;
    
    const userResult = await pool.request()
      .input('userId', userId)
      .query(userQuery);
    
    const userInfo = userResult.recordset[0];
    
    let query = `
      SELECT c.*, 
             STRING_AGG(a.nombre, ', ') as areas_asignadas,
             @area_usuario as area_usuario,
             @descripcion_area_usuario as descripcion_area_usuario
      FROM Caso c
      LEFT JOIN CasoArea ca ON c.id_caso = ca.id_caso
      LEFT JOIN Area a ON ca.id_area = a.id_area
    `;
    
    const conditions = [];
    if (estado) {
      conditions.push('c.estado = @estado');
    }
    if (id_area) {
      conditions.push('ca.id_area = @id_area');
    }
    
    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }
    
    query += ' GROUP BY c.id_caso, c.titulo, c.descripcion, c.tipo, c.estado, c.fecha_creacion, c.fecha_cierre ORDER BY c.fecha_creacion DESC';
    
    const request = pool.request();
    if (estado) request.input('estado', estado);
    if (id_area) request.input('id_area', parseInt(id_area));
    request.input('area_usuario', userInfo.area_usuario || 'Sin área asignada');
    request.input('descripcion_area_usuario', userInfo.descripcion_area_usuario || '');
    
    const result = await request.query(query);
    res.json(result.recordset);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error obteniendo casos', error: err.message });
  }
});

/**
 * @swagger
 * /api/casos:
 *   post:
 *     tags: [Casos]
 *     summary: Crea un nuevo caso y asigna áreas
 *     description: Crea un nuevo caso en el sistema y lo asigna a las áreas especificadas
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - titulo
 *               - tipo
 *             properties:
 *               titulo:
 *                 type: string
 *                 example: "Accidente en planta de producción"
 *               descripcion:
 *                 type: string
 *                 example: "Descripción detallada del accidente ocurrido"
 *               tipo:
 *                 type: string
 *                 example: "Accidente"
 *               estado:
 *                 type: string
 *                 enum: [Iniciado, "En proceso", Finalizado]
 *                 default: "Iniciado"
 *               areas:
 *                 type: array
 *                 items:
 *                   type: integer
 *                 example: [1, 2, 3]
 *     responses:
 *       200:
 *         description: Caso creado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 id_caso:
 *                   type: integer
 *                   example: 1
 *       401:
 *         description: Token de autenticación requerido
 *       500:
 *         description: Error interno del servidor
 */
routerCasos.post('/', authMW, async (req, res) => {
  try {
    const { titulo, descripcion, tipo, estado, areas } = req.body; // areas: [id_area,...]
    const pool = await poolP3;
    const insert = await pool.request()
      .input('titulo', titulo)
      .input('descripcion', descripcion || null)
      .input('tipo', tipo)
      .input('estado', estado || 'Iniciado')
      .query(`INSERT INTO Caso (titulo, descripcion, tipo, estado) VALUES (@titulo, @descripcion, @tipo, @estado); SELECT SCOPE_IDENTITY() as id_caso;`);
    const id_caso = insert.recordset[0].id_caso;

    if (Array.isArray(areas)) {
      for (const id_area of areas) {
        await pool.request()
          .input('id_caso', id_caso)
          .input('id_area', id_area)
          .input('rol_area', null)
          .query('INSERT INTO CasoArea (id_caso, id_area, rol_area) VALUES (@id_caso, @id_area, @rol_area);');
      }
    }

    res.json({ id_caso });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error creando caso', error: err.message });
  }
});

/**
 * @swagger
 * /api/casos/{id}:
 *   get:
 *     tags: [Casos]
 *     summary: Obtiene un caso específico con sus áreas y seguimientos
 *     description: Retorna la información completa de un caso incluyendo áreas asignadas, seguimientos y adjuntos
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del caso a obtener
 *     responses:
 *       200:
 *         description: Caso obtenido exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 caso:
 *                   type: object
 *                   properties:
 *                     id_caso:
 *                       type: integer
 *                     titulo:
 *                       type: string
 *                     descripcion:
 *                       type: string
 *                     tipo:
 *                       type: string
 *                     estado:
 *                       type: string
 *                     fecha_creacion:
 *                       type: string
 *                       format: date-time
 *                 areas:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id_area:
 *                         type: integer
 *                       nombre:
 *                         type: string
 *                 seguimientos:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id_seguimiento:
 *                         type: integer
 *                       id_caso:
 *                         type: integer
 *                       id_usuario:
 *                         type: integer
 *                       descripcion:
 *                         type: string
 *                       fecha_seguimiento:
 *                         type: string
 *                         format: date-time
 *                       usuario:
 *                         type: string
 *                         example: "Pérez González Juan Carlos"
 *                         description: Nombre completo del usuario que creó el seguimiento
 *                       area_usuario:
 *                         type: string
 *                         example: "Recursos Humanos"
 *                         description: Área a la que pertenece el usuario que creó el seguimiento
 *                       descripcion_area_usuario:
 *                         type: string
 *                         example: "Área encargada de gestión de personal"
 *                         description: Descripción del área del usuario que creó el seguimiento
 *                 adjuntos:
 *                   type: array
 *                   items:
 *                     type: object
 *       401:
 *         description: Token de autenticación requerido
 *       404:
 *         description: Caso no encontrado
 *       500:
 *         description: Error interno del servidor
 */
routerCasos.get('/:id', authMW, async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    const pool = await poolP3;
    const caso = await pool.request().input('id', id).query('SELECT * FROM Caso WHERE id_caso = @id');
    if (!caso.recordset.length) return res.status(404).json({ message: 'Caso no encontrado' });

    const areas = await pool.request().input('id', id).query(`SELECT a.id_area, a.nombre, a.listaCorreo FROM CasoArea ca JOIN Area a ON ca.id_area = a.id_area WHERE ca.id_caso = @id`);
    const seguimientos = await pool.request().input('id', id).query(`
      SELECT s.*, 
             u.apellidos+' '+u.nombres as usuario,
             a.nombre as area_usuario,
             a.descripcion as descripcion_area_usuario
      FROM Seguimiento s 
      JOIN Usuario u ON s.id_usuario = u.id_usuario 
      LEFT JOIN Area a ON u.id_area = a.id_area
      WHERE s.id_caso = @id 
      ORDER BY s.fecha_seguimiento ASC
    `);
    const adjuntos = await pool.request().input('id', id).query(`SELECT id_adjunto, nombre_archivo, tipo_mime, ruta_archivo, fecha_subida, id_seguimiento FROM Adjunto WHERE id_caso = @id`);

    res.json({ caso: caso.recordset[0], areas: areas.recordset, seguimientos: seguimientos.recordset, adjuntos: adjuntos.recordset });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error obteniendo caso', error: err.message });
  }
});

module.exports = routerCasos;