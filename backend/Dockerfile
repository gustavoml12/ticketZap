# syntax=docker/dockerfile:1.7-labs

FROM node:20-alpine as build

WORKDIR /usr/src/app

# Copiar apenas arquivos necessários para instalar dependências
COPY package*.json ./

# Usar cache para npm install
RUN --mount=type=cache,target=/root/.npm \
    npm ci --only=production

# Copiar o restante dos arquivos
COPY . .

RUN mkdir -p public/settings && \
    echo '{"name":"TicketZap","short_name":"TicketZap","start_url":"/","display":"standalone","theme_color":"#000000","background_color":"#ffffff"}' > public/manifest.json && \
    echo '{"value":"#2196f3"}' > public/settings/primaryColorLight.json && \
    echo '{"value":""}' > public/settings/appLogoLight.json && \
    echo '{"value":"light"}' > public/settings/theme.json

RUN npm run build

FROM node:20-alpine

WORKDIR /usr/src/app

# Instalar dependências em uma única camada para reduzir o tamanho da imagem
RUN apk add --no-cache wget curl postgresql-client redis && \
    npm install -g pm2 && \
    addgroup -g 1001 -S appuser && \
    adduser -u 1001 -S appuser -G appuser

# Copiar apenas os arquivos necessários do estágio de build
COPY --from=build --chown=appuser:appuser /usr/src/app/dist ./dist
COPY --from=build --chown=appuser:appuser /usr/src/app/node_modules ./node_modules
COPY --from=build --chown=appuser:appuser /usr/src/app/package.json ./package.json
COPY --from=build --chown=appuser:appuser /usr/src/app/public ./public

# Criar diretórios para mídia e definir permissões de forma mais eficiente
RUN mkdir -p /usr/src/app/uploads /usr/src/app/private /usr/src/app/logs /usr/src/app/config && \
    chown -R appuser:appuser /usr/src/app && \
    chmod -R 755 /usr/src/app

# Criar arquivo de configuração do Sequelize
COPY --chown=appuser:appuser <<EOF /usr/src/app/config/config.json
{
  "development": {
    "url": "${DATABASE_URL}",
    "dialect": "postgres",
    "timezone": "-03:00",
    "logging": false,
    "define": {
      "charset": "utf8",
      "collate": "utf8_general_ci"
    },
    "pool": {
      "max": 60,
      "min": 5,
      "acquire": 30000,
      "idle": 10000
    },
    "dialectOptions": {
      "ssl": false
    }
  },
  "test": {
    "url": "${DATABASE_URL}",
    "dialect": "postgres",
    "timezone": "-03:00",
    "logging": false,
    "define": {
      "charset": "utf8",
      "collate": "utf8_general_ci"
    },
    "pool": {
      "max": 60,
      "min": 5,
      "acquire": 30000,
      "idle": 10000
    },
    "dialectOptions": {
      "ssl": false
    }
  },
  "production": {
    "url": "${DATABASE_URL}",
    "dialect": "postgres",
    "timezone": "-03:00",
    "logging": false,
    "define": {
      "charset": "utf8",
      "collate": "utf8_general_ci"
    },
    "pool": {
      "max": 60,
      "min": 5,
      "acquire": 30000,
      "idle": 10000
    },
    "dialectOptions": {
      "ssl": false
    }
  }
}
EOF

# Copiar scripts de inicialização
COPY --chown=appuser:appuser start.sh /usr/src/app/start.sh
COPY --chown=appuser:appuser create_tables.sql /usr/src/app/create_tables.sql
RUN chmod +x /usr/src/app/start.sh

# Criar arquivo de configuração do PM2
COPY --chown=appuser:appuser <<EOF /usr/src/app/ecosystem.config.js
module.exports = {
  apps: [{
    name: 'backend',
    script: './dist/server.js',
    instances: 1,
    exec_mode: 'fork',
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production'
    }
  }]
}
EOF

# Expor a porta
EXPOSE 3000

# Verificação de saúde
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget --spider -q http://localhost:3000/health || exit 1

# Mudar para o usuário não-root
USER appuser

# Iniciar a aplicação
CMD ["/usr/src/app/start.sh"]
