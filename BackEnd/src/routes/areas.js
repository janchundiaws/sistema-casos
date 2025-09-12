// ------------------------------
// src/routes/areas.js
// ------------------------------
const express3 = require('express');
const routerAreas = express3.Router();
const { poolPromise: poolP2 } = require('../db');
const { authenticateToken: authMiddleware } = require('../middleware/auth');

/**
 * @swagger
 * tags:
 *   name: Areas
 *   description: Gestión de áreas
 */

/**
 * @swagger
 * /api/areas:
 *   get:
 *     tags: [Areas]
 *     summary: Obtiene la lista de todas las áreas
 *     description: Retorna un array con todas las áreas disponibles en el sistema (sin autenticación requerida)
 *     responses:
 *       200:
 *         description: Lista de áreas obtenida exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id_area:
 *                     type: integer
 *                     example: 1
 *                   nombre:
 *                     type: string
 *                     example: "Recursos Humanos"
 *                   descripcion:
 *                     type: string
 *                     example: "Área encargada de gestión de personal"
 *       500:
 *         description: Error interno del servidor
 */
routerAreas.get('/', async (req, res) => {
  try {
    const pool = await poolP2;
    const result = await pool.request().query('SELECT id_area, nombre, descripcion FROM Area');
    res.json(result.recordset);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error buscando áreas' });
  }
});

/**
 * @swagger
 * /api/areas:
 *   post:
 *     tags: [Areas]
 *     summary: Crea una nueva área
 *     description: Crea una nueva área en el sistema
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - nombre
 *             properties:
 *               nombre:
 *                 type: string
 *                 example: "Recursos Humanos"
 *               descripcion:
 *                 type: string
 *                 example: "Área encargada de gestión de personal"
 *     responses:
 *       200:
 *         description: Área creada exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 id_area:
 *                   type: integer
 *                   example: 1
 *       401:
 *         description: Token de autenticación requerido
 *       500:
 *         description: Error interno del servidor
 */
routerAreas.post('/', authMiddleware, async (req, res) => {
  try {
    const { nombre, descripcion } = req.body;
    const pool = await poolP2;
    const result = await pool.request()
      .input('nombre', nombre)
      .input('descripcion', descripcion || null)
      .query('INSERT INTO Area (nombre, descripcion) VALUES (@nombre, @descripcion); SELECT SCOPE_IDENTITY() as id_area;');
    res.json({ id_area: result.recordset[0].id_area });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error creando área' });
  }
});

module.exports = routerAreas;