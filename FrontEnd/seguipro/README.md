# Seguipro - Sistema de Seguimiento de Casos

Una aplicación Flutter responsiva para el seguimiento y gestión de casos, desarrollada para conectarse con el backend Node.js.

## Características

- 🔐 **Autenticación**: Login y registro de usuarios
- 📋 **Gestión de Casos**: Crear, visualizar y gestionar casos
- 📝 **Seguimientos**: Agregar seguimientos a los casos con retroalimentación
- 📎 **Adjuntos**: Subir archivos adjuntos a casos y seguimientos
- 📱 **Responsivo**: Diseño adaptativo para móviles, tablets y escritorio
- 🎨 **Material Design 3**: Interfaz moderna y atractiva

## Funcionalidades Principales

### Autenticación
- Login con ID de usuario y contraseña
- Registro de nuevos usuarios con selección de área
- Almacenamiento seguro de tokens JWT

### Gestión de Casos
- Lista de casos con filtros por estado y área
- Creación de nuevos casos con asignación de áreas
- Visualización detallada de casos
- Estados: Iniciado, En proceso, Finalizado

### Seguimientos
- Agregar seguimientos con retroalimentación
- Cambio de estado del caso desde el seguimiento
- Historial cronológico de seguimientos
- Adjuntar archivos a seguimientos

### Archivos Adjuntos
- Subida de múltiples archivos
- Soporte para cualquier tipo de archivo
- Visualización de archivos adjuntos
- Iconos según tipo de archivo

## Tecnologías Utilizadas

- **Flutter**: Framework de desarrollo móvil
- **Dio**: Cliente HTTP para comunicación con la API
- **Flutter Secure Storage**: Almacenamiento seguro de tokens
- **File Picker**: Selección de archivos
- **Shared Preferences**: Preferencias de usuario
- **Intl**: Formateo de fechas

## Estructura del Proyecto

```
lib/
├── models/           # Modelos de datos
│   ├── usuario.dart
│   ├── area.dart
│   ├── caso.dart
│   ├── seguimiento.dart
│   └── adjunto.dart
├── services/         # Servicios de API
│   └── api_service.dart
├── screens/          # Pantallas de la aplicación
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── create_caso_screen.dart
│   ├── caso_detail_screen.dart
│   └── add_seguimiento_screen.dart
├── widgets/          # Widgets reutilizables
│   └── responsive_layout.dart
├── utils/            # Utilidades
│   └── responsive.dart
└── main.dart         # Punto de entrada
```

## Configuración

1. **Instalar dependencias**:
   ```bash
   flutter pub get
   ```

2. **Configurar la URL del backend**:
   Editar `lib/services/api_service.dart` y cambiar la variable `baseUrl`:
   ```dart
   static const String baseUrl = 'http://tu-servidor:puerto/api';
   ```

3. **Ejecutar la aplicación**:
   ```bash
   flutter run
   ```

## API Backend

La aplicación se conecta a un backend Node.js con las siguientes rutas:

- `POST /api/auth/login` - Autenticación
- `POST /api/auth/register` - Registro
- `GET /api/areas` - Listar áreas
- `GET /api/casos` - Listar casos
- `POST /api/casos` - Crear caso
- `GET /api/casos/:id` - Detalle del caso
- `POST /api/seguimientos` - Crear seguimiento
- `POST /api/adjuntos/upload` - Subir archivo

## Diseño Responsivo

La aplicación está diseñada para funcionar en diferentes tamaños de pantalla:

- **Móvil** (< 768px): Layout de una columna
- **Tablet** (768px - 1024px): Layout de dos columnas
- **Escritorio** (> 1024px): Layout de tres columnas

## Características de Seguridad

- Almacenamiento seguro de tokens JWT
- Validación de formularios
- Manejo de errores de red
- Timeout de conexión configurado

## Próximas Mejoras

- [ ] Descarga de archivos adjuntos
- [ ] Notificaciones push
- [ ] Modo offline
- [ ] Búsqueda avanzada
- [ ] Reportes y estadísticas
- [ ] Temas claro/oscuro

## Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.