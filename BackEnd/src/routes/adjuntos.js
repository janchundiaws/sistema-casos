const express6 = require('express');
const routerAdj = express6.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { poolPromise: poolP5 } = require('../db');
const { authenticateToken: authMW3 } = require('../middleware/auth');
const { v4: uuidv4 } = require('uuid');

// Crear directorio uploads si no existe
const uploadsDir = 'uploads';
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
  console.log('Directorio uploads creado');
}

// Storage local (uploads/)
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadsDir);
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname);
    const name = uuidv4() + ext;
    cb(null, name);
  }
});

// Configuración de multer con límites
const upload = multer({ 
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB límite
    files: 5 // máximo 5 archivos por request
  },
  fileFilter: (req, file, cb) => {
    // Permitir todos los tipos de archivo
    cb(null, true);
  }
});

/**
 * @swagger
 * tags:
 *   name: Adjuntos
 *   description: Subida y gestión de archivos
 */

/**
 * @swagger
 * /api/adjuntos/upload:
 *   post:
 *     tags: [Adjuntos]
 *     summary: Sube un archivo asociado a un caso o seguimiento
 *     description: Permite subir archivos adjuntos a casos o seguimientos específicos
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required:
 *               - file
 *             properties:
 *               file:
 *                 type: string
 *                 format: binary
 *                 description: Archivo a subir
 *               id_caso:
 *                 type: integer
 *                 description: ID del caso (opcional si se especifica id_seguimiento)
 *               id_seguimiento:
 *                 type: integer
 *                 description: ID del seguimiento (opcional si se especifica id_caso)
 *     responses:
 *       200:
 *         description: Archivo subido exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 id_adjunto:
 *                   type: integer
 *                   example: 1
 *                 path:
 *                   type: string
 *                   example: "uploads/uuid-archivo.pdf"
 *       400:
 *         description: Archivo requerido o datos inválidos
 *       401:
 *         description: Token de autenticación requerido
 *       500:
 *         description: Error interno del servidor
 */
// Middleware para manejar errores de multer
const handleMulterError = (err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(413).json({ message: 'El archivo es demasiado grande (máximo 10MB)' });
    }
    if (err.code === 'LIMIT_FILE_COUNT') {
      return res.status(400).json({ message: 'Demasiados archivos (máximo 5)' });
    }
    if (err.code === 'LIMIT_UNEXPECTED_FILE') {
      return res.status(400).json({ message: 'Campo de archivo inesperado' });
    }
  }
  next(err);
};

routerAdj.post('/upload', authMW3, upload.single('file'), handleMulterError, async (req, res) => {
  try {
    console.log('Iniciando subida de archivo...');
    console.log('Body:', req.body);
    console.log('File:', req.file);
    console.log('User:', req.user);

    const { id_caso, id_seguimiento } = req.body;
    const file = req.file;
    
    if (!file) {
      console.log('Error: No se recibió archivo');
      return res.status(400).json({ message: 'Archivo requerido' });
    }

    // Validar que al menos uno de los IDs esté presente
    if (!id_caso && !id_seguimiento) {
      console.log('Error: Se requiere id_caso o id_seguimiento');
      return res.status(400).json({ message: 'Se requiere id_caso o id_seguimiento' });
    }

    console.log('Conectando a la base de datos...');
    const pool = await poolP5;
    
    console.log('Ejecutando query de inserción...');
    const result = await pool.request()
      .input('id_caso', id_caso ? parseInt(id_caso) : null)
      .input('id_seguimiento', id_seguimiento ? parseInt(id_seguimiento) : null)
      .input('nombre_archivo', file.originalname)
      .input('tipo_mime', file.mimetype)
      .input('ruta_archivo', file.path)
      .input('id_usuario', req.user.id_usuario)
      .query(`INSERT INTO Adjunto (id_caso, id_seguimiento, nombre_archivo, tipo_mime, ruta_archivo, id_usuario)
              VALUES (@id_caso, @id_seguimiento, @nombre_archivo, @tipo_mime, @ruta_archivo, @id_usuario);
              SELECT SCOPE_IDENTITY() as id_adjunto;`);

    console.log('Archivo subido exitosamente:', result.recordset[0]);
    res.json({ 
      id_adjunto: result.recordset[0].id_adjunto, 
      path: file.path,
      nombre_archivo: file.originalname,
      tipo_mime: file.mimetype
    });
  } catch (err) {
    console.error('Error detallado:', err);
    console.error('Stack trace:', err.stack);
    
    // Limpiar archivo si se subió pero falló la DB
    if (req.file && req.file.path) {
      try {
        fs.unlinkSync(req.file.path);
        console.log('Archivo temporal eliminado');
      } catch (cleanupErr) {
        console.error('Error limpiando archivo temporal:', cleanupErr);
      }
    }
    
    res.status(500).json({ 
      message: 'Error subiendo archivo', 
      error: err.message,
      details: process.env.NODE_ENV === 'development' ? err.stack : undefined
    });
  }
});

module.exports = routerAdj;
