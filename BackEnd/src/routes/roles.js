// ------------------------------
// src/routes/roles.js
// ------------------------------
const express4 = require('express');
const routerRoles = express4.Router();
const { poolPromise: poolP4 } = require('../db');

/**
 * @swagger
 * tags:
 *   name: Roles
 *   description: Gestión de roles
 */

/**
 * @swagger
 * /api/roles:
 *   get:
 *     tags: [Roles]
 *     summary: Obtiene la lista de todos los roles
 *     description: Retorna un array con todos los roles disponibles en el sistema (sin autenticación requerida)
 *     responses:
 *       200:
 *         description: Lista de roles obtenida exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id_rol:
 *                     type: integer
 *                     example: 1
 *                   nombre:
 *                     type: string
 *                     example: "Administrador"
 *                   descripcion:
 *                     type: string
 *                     example: "Rol con acceso completo al sistema"
 *       500:
 *         description: Error interno del servidor
 */
routerRoles.get('/', async (req, res) => {
  try {
    const pool = await poolP4;
    const result = await pool.request().query('SELECT id_rol, nombre, descripcion FROM Rol');
    res.json(result.recordset);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error buscando roles' });
  }
});

/**
 * @swagger
 * /api/roles:
 *   post:
 *     tags: [Roles]
 *     summary: Crea un nuevo rol
 *     description: Crea un nuevo rol en el sistema
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
 *                 example: "Supervisor"
 *               descripcion:
 *                 type: string
 *                 example: "Rol de supervisión de equipos"
 *     responses:
 *       200:
 *         description: Rol creado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 id_rol:
 *                   type: integer
 *                   example: 1
 *       500:
 *         description: Error interno del servidor
 */
routerRoles.post('/', async (req, res) => {
  try {
    const { nombre, descripcion } = req.body;
    const pool = await poolP4;
    const result = await pool.request()
      .input('nombre', nombre)
      .input('descripcion', descripcion || null)
      .query('INSERT INTO Rol (nombre, descripcion) VALUES (@nombre, @descripcion); SELECT SCOPE_IDENTITY() as id_rol;');
    res.json({ id_rol: result.recordset[0].id_rol });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error creando rol' });
  }
});

module.exports = routerRoles;
