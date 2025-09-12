# Seguipro - Docker Setup

Este proyecto incluye configuración completa de Docker para desarrollo y producción.

## Estructura del Proyecto

```
GYT-Seguipro/
├── BackEnd/                 # API Node.js
│   ├── Dockerfile
│   ├── .dockerignore
│   └── src/
├── FrontEnd/               # Aplicación Flutter Web
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── nginx.conf
│   └── seguipro/
├── docker-compose.yml      # Orquestación de servicios
├── init-db.sql            # Script de inicialización de BD
└── env.docker             # Variables de entorno
```

## Servicios Incluidos

- **database**: SQL Server 2022 Express
- **backend**: API Node.js con Express
- **frontend**: Aplicación Flutter Web con Nginx

## Comandos de Docker

### Desarrollo

```bash
# Construir y ejecutar todos los servicios
docker-compose up --build

# Ejecutar en segundo plano
docker-compose up -d --build

# Ver logs
docker-compose logs -f

# Parar servicios
docker-compose down
```

### Producción

```bash
# Construir para producción
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up --build

# Ejecutar en segundo plano
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## Configuración

### Variables de Entorno

Edita el archivo `env.docker` para configurar:

- **Base de datos**: Credenciales de SQL Server
- **JWT**: Clave secreta para tokens
- **CORS**: Orígenes permitidos

### Puertos

- **Frontend**: http://localhost:80
- **Backend**: http://localhost:3000
- **Base de datos**: localhost:1433

### Volúmenes

- **db_data**: Datos persistentes de SQL Server
- **uploads**: Archivos subidos en el backend

## Acceso a la Aplicación

1. **Frontend**: http://localhost
2. **API Docs**: http://localhost:3000/api-docs
3. **Base de datos**: localhost:1433 (usuario: sa, contraseña: YourStrong@Passw0rd)

## Desarrollo

### Backend

```bash
# Entrar al contenedor
docker-compose exec backend sh

# Instalar dependencias
npm install

# Ejecutar en modo desarrollo
npm run dev
```

### Frontend

```bash
# Entrar al contenedor
docker-compose exec frontend sh

# Ejecutar Flutter
flutter run -d web-server --web-port 8080
```

## Solución de Problemas

### Verificar estado de servicios

```bash
docker-compose ps
```

### Ver logs específicos

```bash
docker-compose logs backend
docker-compose logs frontend
docker-compose logs database
```

### Reiniciar un servicio

```bash
docker-compose restart backend
```

### Limpiar todo

```bash
docker-compose down -v
docker system prune -a
```

## Notas Importantes

1. **Base de datos**: La primera ejecución puede tardar varios minutos en inicializar SQL Server
2. **Archivos**: Los uploads se mantienen en el volumen `uploads`
3. **Seguridad**: Cambia las contraseñas por defecto en producción
4. **CORS**: Configura los orígenes permitidos según tu entorno

## Estructura de Red

Todos los servicios están en la red `seguipro-network` y pueden comunicarse entre sí usando los nombres de los servicios como hostnames.
