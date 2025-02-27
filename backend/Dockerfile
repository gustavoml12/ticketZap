FROM node:20-alpine

WORKDIR /usr/src/app

# Instalar dependências do sistema
RUN apk add --no-cache postgresql-client

# Copiar arquivos de configuração
COPY package*.json ./

# Instalar dependências
RUN npm install

# Copiar código-fonte
COPY . .

# Copiar scripts de inicialização
COPY start.sh /usr/src/app/start.sh
COPY create_tables.sql /usr/src/app/create_tables.sql

# Tornar scripts executáveis
RUN chmod +x /usr/src/app/start.sh

# Construir a aplicação
RUN npm run build

# Expor porta
EXPOSE 3000

# Comando para iniciar a aplicação
CMD ["/bin/sh", "/usr/src/app/start.sh"]
