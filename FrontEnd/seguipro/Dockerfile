# Etapa 1: Environment to install flutter and build web
FROM debian:latest AS build-env
 
# Install all needed stuff
RUN apt-get update && apt-get install -y curl git unzip
 
# Define variables
ARG FLUTTER_SDK=/usr/local/flutter
ARG FLUTTER_VERSION=3.32.7
ARG APP=/app/
 
# Clone flutter
RUN git clone https://github.com/flutter/flutter.git $FLUTTER_SDK
# Change dir to current flutter folder and checkout the specific version
RUN cd $FLUTTER_SDK && git fetch && git checkout $FLUTTER_VERSION
 
# Setup the flutter path as an environmental variable
ENV PATH="$FLUTTER_SDK/bin:$FLUTTER_SDK/bin/cache/dart-sdk/bin:${PATH}"
 
# Run flutter doctor to see if all was installed ok
RUN flutter doctor -v
 
# Create folder to copy source code
RUN mkdir $APP
 
# Etapa 2: Copiar el código fuente
# Copy source code to folder
COPY . $APP
 
# Etapa 3: Configurar el entorno y construir la aplicación
# Setup new folder as the working directory
WORKDIR $APP
 
# Run build: 1 - clean, 2 - pub get, 3 - build web
RUN flutter clean && \
     flutter pub get
#     flutter packages pub run build_runner build --delete-conflicting-outputs && \
RUN flutter build web
 
# Etapa 4: Despliegue utilizando NGINX
# Use nginx to deploy
FROM nginx:1.25.2-alpine
 
# Copiar el contenido de la aplicación web compilada a NGINX
COPY --from=build-env /app/build/web /usr/share/nginx/html
 
# Exponer el puerto y ejecutar NGINX
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
 