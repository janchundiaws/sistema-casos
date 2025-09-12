const express2 = require('express');
const routerAuth = express2.Router();
const bcrypt = require('bcrypt');
const jwt2 = require('jsonwebtoken');
const { poolPromise: poolP } = require('../db');

/**
 * @swagger
 * tags:
 *   name: Auth
 *   description: Autenticación y usuarios
 */

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     tags: [Auth]
 *     summary: Registra un nuevo usuario en el sistema
 *     description: Crea un nuevo usuario con contraseña encriptada
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - password
 *               - id_area
 *               - id_rol
 *               - username
 *               - nombres
 *               - apellidos
 *             properties:
 *               password:
 *                 type: string
 *                 minLength: 6
 *                 example: "password123"
 *               id_area:
 *                 type: integer
 *                 example: 1
 *               id_rol:
 *                 type: integer
 *                 example: 1
 *               username:
 *                 type: string
 *                 example: "jperez"
 *               nombres:
 *                 type: string
 *                 example: "Juan Carlos"
 *               apellidos:
 *                 type: string
 *                 example: "Pérez González"
 *     responses:
 *       200:
 *         description: Usuario creado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 id_usuario:
 *                   type: integer
 *                   example: 1
 *       400:
 *         description: Datos de entrada inválidos
 *       500:
 *         description: Error interno del servidor
 */
routerAuth.post('/register', async (req, res) => {
  try {
    const { password, id_area, id_rol, username, nombres, apellidos } = req.body;
    
    // Validar campos requeridos
    if (!password || !id_area || !id_rol || !username || !nombres || !apellidos) {
      return res.status(400).json({ message: 'Todos los campos son requeridos' });
    }

    const pool = await poolP;

    // Verificar que el username no exista
    const existingUser = await pool.request()
      .input('username', username)
      .query('SELECT id_usuario FROM Usuario WHERE username = @username');
    
    if (existingUser.recordset.length > 0) {
      return res.status(400).json({ message: 'El nombre de usuario ya existe' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashed = await bcrypt.hash(password, salt);

    const result = await pool.request()
      .input('id_area', id_area)
      .input('id_rol', id_rol)
      .input('username', username)
      .input('nombres', nombres)
      .input('apellidos', apellidos)
      .query(`INSERT INTO Usuario (id_area, id_rol, username, nombres, apellidos)
              VALUES (@id_area, @id_rol, @username, @nombres, @apellidos);

              SELECT SCOPE_IDENTITY() as id_usuario;`);

    const newId = result.recordset && result.recordset[0] ? result.recordset[0].id_usuario : null;
    if (!newId) return res.status(500).json({ message: 'No se pudo crear usuario' });

    await pool.request()
      .input('id_usuario', newId)
      .input('password_hash', hashed)
      .query(`INSERT INTO UsersAuth (id_usuario, password_hash) VALUES (@id_usuario, @password_hash);`);

    res.json({ id_usuario: newId });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error en registro', error: err.message });
  }
});

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     tags: [Auth]
 *     summary: Inicia sesión y devuelve JWT
 *     description: Autentica un usuario y devuelve un token JWT válido por 8 horas
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - username
 *               - password
 *             properties:
 *               username:
 *                 type: string
 *                 example: "jperez"
 *               password:
 *                 type: string
 *                 example: "password123"
 *     responses:
 *       200:
 *         description: Login exitoso
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 token:
 *                   type: string
 *                   example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
 *                 usuario:
 *                   type: object
 *                   properties:
 *                     id_usuario:
 *                       type: integer
 *                       example: 1
 *                     username:
 *                       type: string
 *                       example: "jperez"
 *                     nombres:
 *                       type: string
 *                       example: "Juan Carlos"
 *                     apellidos:
 *                       type: string
 *                       example: "Pérez González"
 *                     id_area:
 *                       type: integer
 *                       example: 1
 *                     id_rol:
 *                       type: integer
 *                       example: 1
 *       400:
 *         description: Credenciales inválidas
 *       500:
 *         description: Error interno del servidor
 */
routerAuth.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    // Validar campos requeridos
    if (!username || !password) {
      return res.status(400).json({ message: 'Username y password son requeridos' });
    }
    
    const pool = await poolP;
    
    // Obtener información completa del usuario por username
    const userRes = await pool.request()
      .input('username', username)
      .query(`SELECT id_usuario, username, nombres, apellidos, id_area, id_rol 
              FROM Usuario WHERE username = @username`);

    if (!userRes.recordset.length) return res.status(400).json({ message: 'Usuario no encontrado' });
    const user = userRes.recordset[0];

    // Verificar contraseña
    const authRes = await pool.request()
      .input('id_usuario', user.id_usuario)
      .query('SELECT password_hash FROM UsersAuth WHERE id_usuario = @id_usuario');
    
    if (!authRes.recordset.length) return res.status(400).json({ message: 'Credenciales inválidas' });
    
    const valid = await bcrypt.compare(password, authRes.recordset[0].password_hash);
    if (!valid) return res.status(400).json({ message: 'Credenciales inválidas' });

    const token = jwt2.sign({ id_usuario: user.id_usuario }, process.env.JWT_SECRET, { expiresIn: '8h' });
    
    res.json({ 
      token,
      usuario: {
        id_usuario: user.id_usuario,
        username: user.username,
        nombres: user.nombres,
        apellidos: user.apellidos,
        id_area: user.id_area,
        id_rol: user.id_rol
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error en login', error: err.message });
  }
});

/**
 * @swagger
 * /api/auth/user/{id}:
 *   get:
 *     tags: [Auth]
 *     summary: Obtiene información de un usuario específico
 *     description: Devuelve la información completa de un usuario por su ID
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del usuario
 *     responses:
 *       200:
 *         description: Información del usuario obtenida exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 id_usuario:
 *                   type: integer
 *                   example: 1
 *                 username:
 *                   type: string
 *                   example: "jperez"
 *                 nombres:
 *                   type: string
 *                   example: "Juan Carlos"
 *                 apellidos:
 *                   type: string
 *                   example: "Pérez González"
 *                 id_area:
 *                   type: integer
 *                   example: 1
 *                 id_rol:
 *                   type: integer
 *                   example: 1
 *       404:
 *         description: Usuario no encontrado
 *       500:
 *         description: Error interno del servidor
 */
routerAuth.get('/user/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const pool = await poolP;
    
    const userRes = await pool.request()
      .input('id_usuario', id)
      .query(`SELECT id_usuario, username, nombres, apellidos, id_area, id_rol 
              FROM Usuario WHERE id_usuario = @id_usuario`);

    if (!userRes.recordset.length) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }

    const user = userRes.recordset[0];
    res.json({
      id_usuario: user.id_usuario,
      username: user.username,
      nombres: user.nombres,
      apellidos: user.apellidos,
      id_area: user.id_area,
      id_rol: user.id_rol
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error obteniendo usuario', error: err.message });
  }
});

module.exports = routerAuth;