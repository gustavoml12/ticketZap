# syntax=docker/dockerfile:1.7-labs

FROM node:20-alpine as build

WORKDIR /usr/src/app

# Copiar apenas os arquivos necessários para instalar dependências
COPY package*.json ./

# Instalar dependências usando cache
RUN --mount=type=cache,target=/root/.npm \
    npm install

# Copiar o resto dos arquivos
COPY . .

# Compilar TypeScript (apenas uma vez)
RUN npm run build

# Configurar arquivos estáticos
RUN mkdir -p public/settings && \
    echo '{"name":"TicketZap","short_name":"TicketZap","start_url":"/","display":"standalone","theme_color":"#000000","background_color":"#ffffff"}' > public/manifest.json && \
    echo '{"value":"#2196f3"}' > public/settings/primaryColorLight.json && \
    echo '{"value":"#2196f3"}' > public/settings/primaryColorDark.json && \
    echo '{"value":"TicketZap"}' > public/settings/appName.json && \
    echo '{"value":""}' > public/settings/appLogoLight.json && \
    echo '{"value":""}' > public/settings/appLogoDark.json && \
    echo '{"value":""}' > public/settings/appLogoFavicon.json && \
    echo '{"value":"light"}' > public/settings/theme.json && \
    echo '{"value":false}' > public/settings/allowSignup.json

FROM node:20-alpine

WORKDIR /usr/src/app

# Instalar apenas as dependências necessárias
RUN apk add --no-cache \
    postgresql-client \
    bash \
    redis \
    wget \
    curl \
    && npm install -g pm2

# Criar usuário não-root
RUN addgroup -S appuser && \
    adduser -S appuser -G appuser

# Criar diretórios necessários
RUN mkdir -p /usr/src/app/uploads && \
    mkdir -p /usr/src/app/private && \
    mkdir -p /usr/src/app/logs && \
    mkdir -p /usr/src/app/config && \
    mkdir -p /usr/src/app/dist && \
    mkdir -p /usr/src/app/public/settings && \
    mkdir -p /usr/src/app/seeders && \
    mkdir -p /usr/src/app/migrations

# Copiar apenas os arquivos necessários da etapa de build
COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/package.json ./
COPY --from=build /usr/src/app/start.sh ./
COPY --from=build /usr/src/app/public ./public
COPY --from=build /usr/src/app/config ./config
COPY --from=build /usr/src/app/src/database/seeds ./seeders
COPY --from=build /usr/src/app/src/database/migrations ./migrations
COPY --from=build /usr/src/app/.sequelizerc ./

# Definir permissões depois de copiar todos os arquivos
RUN chmod +x /usr/src/app/start.sh && \
    chown -R appuser:appuser /usr/src/app && \
    chmod -R 755 /usr/src/app

# Configurar PM2
RUN echo "module.exports = {apps:[{name:\"backend\",script:\"./dist/server.js\",instances:1,exec_mode:\"fork\",watch:false,max_memory_restart:\"1G\",env:{NODE_ENV:\"production\"}}]}" > /usr/src/app/ecosystem.config.js

# Adicionar HEALTHCHECK
HEALTHCHECK --interval=10s --timeout=5s --start-period=40s --retries=3 \
    CMD wget --spider -q http://localhost:3000/ || exit 1

# Configurar variáveis de ambiente
ENV NODE_ENV=production \
    PORT=3000 \
    FRONTEND_URL=${COOLIFY_FQDN} \
    BASE_URL=${COOLIFY_URL} \
    EMAIL_ADDRESS=admin@admin.com \
    DATABASE_URL=${DATABASE_URL}

# Adicionar labels para o Traefik
LABEL traefik.enable=true \
    traefik.http.routers.backend.rule="PathPrefix(`/api`)" \
    traefik.http.services.backend.loadbalancer.server.port=3000 \
    traefik.http.middlewares.backend-strip.stripprefix.prefixes=/api \
    traefik.http.routers.backend.middlewares=backend-strip@docker

USER appuser

EXPOSE 3000

CMD ["/usr/src/app/start.sh"]
