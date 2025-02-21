# syntax=docker/dockerfile:1.7-labs

FROM node:20-alpine as build

WORKDIR /usr/src/app

COPY package*.json ./

RUN --mount=type=cache,target=/root/.npm \
    npm install

COPY . .

RUN mkdir -p public/settings && \
    echo '{"name":"TicketZap","short_name":"TicketZap","start_url":"/","display":"standalone","theme_color":"#000000","background_color":"#ffffff"}' > public/manifest.json && \
    echo '{"value":"#2196f3"}' > public/settings/primaryColorLight.json && \
    echo '{"value":""}' > public/settings/appLogoLight.json && \
    echo '{"value":"light"}' > public/settings/theme.json

RUN npm run build

FROM node:20-alpine

WORKDIR /usr/src/app

RUN apk add --no-cache wget curl postgresql-client && \
    npm install -g pm2

# Copiar apenas os arquivos necessários
COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/package.json ./package.json

# Criar diretórios para mídia
RUN mkdir -p /usr/src/app/public && \
    mkdir -p /usr/src/app/uploads && \
    mkdir -p /usr/src/app/logs && \
    chown -R node:node /usr/src/app && \
    chmod -R 755 /usr/src/app/public && \
    chmod -R 755 /usr/src/app/uploads && \
    chmod -R 755 /usr/src/app/logs

# Copiar arquivos públicos do build
COPY --from=build /usr/src/app/public ./public

USER node

# Criar arquivo de configuração do PM2
COPY --chown=node:node <<EOF /usr/src/app/ecosystem.config.js
module.exports = {
  apps: [{
    name: 'ticketz-backend',
    script: 'dist/server.js',
    instances: 1,
    exec_mode: 'cluster',
    max_memory_restart: '400M',
    env: {
      NODE_ENV: 'production'
    },
    env_production: {
      NODE_ENV: 'production'
    }
  }]
}
EOF

# Criar arquivo de entrypoint
COPY --chown=node:node <<EOF /usr/src/app/docker-entrypoint.sh
#!/bin/sh
set -e

# Criar diretórios necessários caso não existam
mkdir -p /usr/src/app/public
mkdir -p /usr/src/app/uploads
mkdir -p /usr/src/app/logs

# Ajustar permissões
chmod -R 755 /usr/src/app/public
chmod -R 755 /usr/src/app/uploads
chmod -R 755 /usr/src/app/logs

# Iniciar a aplicação
exec pm2-runtime start ecosystem.config.js --env production
EOF

RUN chmod +x /usr/src/app/docker-entrypoint.sh

ENTRYPOINT ["/usr/src/app/docker-entrypoint.sh"]
