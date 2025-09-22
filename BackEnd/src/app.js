const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const dotenv3 = require('dotenv');
dotenv3.config();

const { poolPromise } = require('./db');
const authRoutes = require('./routes/auth');
const areasRoutes = require('./routes/areas');
const rolesRoutes = require('./routes/roles');
const casosRoutes = require('./routes/casos');
const seguimientosRoutes = require('./routes/seguimientos');
const adjuntosRoutes = require('./routes/adjuntos');
const emailRoutes = require('./routes/email');
//const authADRoutes = require('./routes/authAD');

const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(bodyParser.json());
app.use('/uploads', express.static('uploads'));

// Swagger setup
const swaggerDefinition = {
  openapi: '3.0.0',
  info: {
    title: 'API - Seguimiento de Casos',
    version: '1.0.0',
    description: 'API para gestionar casos, seguimientos, áreas, usuarios y adjuntos.'
  },
  servers: [{ url: `http://localhost:${port}` }],
  components: {
    securitySchemes: {
      bearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: 'Ingresa el token JWT obtenido del endpoint /api/auth/login'
      }
    }
  },
  security: [
    {
      bearerAuth: []
    }
  ]
};

const options = {
  swaggerDefinition,
  apis: ['./src/routes/*.js']
};

const swaggerSpec = swaggerJsdoc(options);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/areas', areasRoutes);
app.use('/api/roles', rolesRoutes);
app.use('/api/casos', casosRoutes);
app.use('/api/seguimientos', seguimientosRoutes);
app.use('/api/adjuntos', adjuntosRoutes);
app.use('/api/email', emailRoutes);
//app.use("/auth", authADRoutes);

// health
app.get('/', (req, res) => res.send('Seguimiento Casos API'));

app.listen(port, () => console.log(`Server running on port ${port}`));

