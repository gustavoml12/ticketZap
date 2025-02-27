# syntax=docker/dockerfile:1.7-labs

FROM node:20-alpine as build

WORKDIR /usr/src/app

COPY package*.json ./
COPY start.sh ./

RUN --mount=type=cache,target=/root/.npm \
    npm install

COPY . .

# Compilar TypeScript
RUN npm run build

# Adicionar script de preparação para migrações
COPY prepare-migrations.js ./prepare-migrations.js

RUN mkdir -p public/settings && \
    echo '{"name":"TicketZap","short_name":"TicketZap","start_url":"/","display":"standalone","theme_color":"#000000","background_color":"#ffffff"}' > public/manifest.json && \
    echo '{"value":"#2196f3"}' > public/settings/primaryColorLight.json && \
    echo '{"value":""}' > public/settings/appLogoLight.json && \
    echo '{"value":"light"}' > public/settings/theme.json

RUN npm run build

FROM node:20-alpine

WORKDIR /usr/src/app

RUN apk add --no-cache \
    postgresql-client \
    curl \
    bash \
    redis \
    vim \
    procps \
    busybox-extras \
    && npm install -g pm2

# Criar usuário não-root
RUN addgroup -S appuser && \
    adduser -S appuser -G appuser

# Criar diretórios necessários
RUN mkdir -p /usr/src/app/dist

# Copiar apenas os arquivos necessários
COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/package.json ./package.json
COPY --from=build /usr/src/app/prepare-migrations.js ./prepare-migrations.js
COPY --from=build /usr/src/app/create_tables.sql ./create_tables.sql
COPY --from=build /usr/src/app/start.sh ./start.sh
COPY --from=build /usr/src/app/dist/server.js ./dist/server.js

# Verificar conteúdo do diretório dist
RUN ls -la /usr/src/app/dist || echo "Diretório dist vazio ou não existe"

# Criar diretórios para mídia e definir permissões
RUN mkdir -p /usr/src/app/public && \
    mkdir -p /usr/src/app/uploads && \
    mkdir -p /usr/src/app/private && \
    mkdir -p /usr/src/app/logs && \
    mkdir -p /usr/src/app/config && \
    chmod +x /usr/src/app/start.sh && \
    chown -R appuser:appuser /usr/src/app && \
    chmod -R 755 /usr/src/app

# Copiar arquivos públicos do build
COPY --from=build --chown=appuser:appuser /usr/src/app/public ./public

# Criar arquivo de configuração do Sequelize
RUN echo "{\"development\":{\"url\":\"${DATABASE_URL}\",\"dialect\":\"postgres\",\"timezone\":\"-03:00\",\"logging\":false,\"define\":{\"charset\":\"utf8\",\"collate\":\"utf8_general_ci\"},\"pool\":{\"max\":60,\"min\":5,\"acquire\":30000,\"idle\":10000},\"dialectOptions\":{\"ssl\":false}},\"test\":{\"url\":\"${DATABASE_URL}\",\"dialect\":\"postgres\",\"timezone\":\"-03:00\",\"logging\":false,\"define\":{\"charset\":\"utf8\",\"collate\":\"utf8_general_ci\"},\"pool\":{\"max\":60,\"min\":5,\"acquire\":30000,\"idle\":10000},\"dialectOptions\":{\"ssl\":false}},\"production\":{\"url\":\"${DATABASE_URL}\",\"dialect\":\"postgres\",\"timezone\":\"-03:00\",\"logging\":false,\"define\":{\"charset\":\"utf8\",\"collate\":\"utf8_general_ci\"},\"pool\":{\"max\":60,\"min\":5,\"acquire\":30000,\"idle\":10000},\"dialectOptions\":{\"ssl\":false}}}" > /usr/src/app/config/config.json && \
    chown appuser:appuser /usr/src/app/config/config.json

# Criar arquivo de configuração do PM2
RUN echo "module.exports = {apps:[{name:\"backend\",script:\"./dist/server.js\",instances:1,exec_mode:\"fork\",watch:false,max_memory_restart:\"1G\",env:{NODE_ENV:\"production\"}}]}" > /usr/src/app/ecosystem.config.js && \
    chown appuser:appuser /usr/src/app/ecosystem.config.js

# Criar script de entrypoint
RUN printf '#!/bin/sh\n\
set -e\n\
\n\
# Verificar se o start.sh existe e tem permissão de execução\n\
if [ ! -f /usr/src/app/start.sh ]; then\n\
    echo "ERRO: /usr/src/app/start.sh não encontrado"\n\
    ls -la /usr/src/app/\n\
    exit 1\n\
fi\n\
\n\
if [ ! -x /usr/src/app/start.sh ]; then\n\
    echo "ERRO: /usr/src/app/start.sh não tem permissão de execução"\n\
    ls -la /usr/src/app/start.sh\n\
    exit 1\n\
fi\n\
\n\
# Executar o script\n\
exec /usr/src/app/start.sh\n' > /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

# Expor a porta
EXPOSE 3000

# Verificação de saúde
HEALTHCHECK --interval=30s --timeout=30s --start-period=220s --retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1

# Mudar para o usuário não-root
USER appuser

# Definir o entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
