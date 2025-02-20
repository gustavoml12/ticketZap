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
COPY --from=build /usr/src/app/public ./public

RUN mkdir -p /usr/src/app/private && \
    chown -R node:node /usr/src/app

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
    error_file: '/usr/src/app/logs/err.log',
    out_file: '/usr/src/app/logs/out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    max_restarts: 5,
    min_uptime: '30s'
  }]
}
EOF

# Criar diretório de logs
RUN mkdir -p /usr/src/app/logs

COPY --chown=node:node <<EOF /usr/src/app/docker-entrypoint.sh
#!/bin/sh
set -e

# Aguardar o PostgreSQL
until pg_isready -h $DB_HOST -p $DB_PORT -U $DB_USER; do
  echo "Aguardando PostgreSQL..."
  sleep 2
done

# Iniciar a aplicação com PM2
exec pm2-runtime start ecosystem.config.js
EOF

RUN chmod +x /usr/src/app/docker-entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["/usr/src/app/docker-entrypoint.sh"]
