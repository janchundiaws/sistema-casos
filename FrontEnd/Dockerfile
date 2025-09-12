# Etapa 1: Construir la aplicación Flutter
FROM ubuntu:22.04 as build

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Instalar Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable /flutter
ENV PATH="/flutter/bin:${PATH}"

# Verificar instalación de Flutter
RUN flutter doctor

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de configuración de Flutter
COPY seguipro/pubspec.yaml seguipro/pubspec.lock ./
COPY seguipro/analysis_options.yaml ./

# Obtener dependencias
RUN flutter pub get

# Copiar código fuente
COPY seguipro/ ./

# Construir aplicación para web
RUN flutter build web --release

# Etapa 2: Servir con Nginx
FROM nginx:alpine

# Copiar archivos construidos
COPY --from=build /app/build/web /usr/share/nginx/html

# Copiar configuración personalizada de Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Exponer puerto
EXPOSE 80

# Comando para iniciar Nginx
CMD ["nginx", "-g", "daemon off;"]
