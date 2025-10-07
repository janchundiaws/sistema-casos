# Usar imagen oficial de Node.js
FROM node:18-alpine

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar dependencias
RUN npm ci --only=production

# Copiar código fuente
COPY . .
#COPY .env ./

# Crear directorio para uploads
RUN mkdir -p uploads

# Exponer puerto
EXPOSE 3000

# Comando para iniciar la aplicación
CMD ["node", "src/app.js"]
