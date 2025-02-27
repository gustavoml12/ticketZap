# syntax=docker/dockerfile:1.7-labs

FROM node:20-alpine as build

WORKDIR /usr/src/app

COPY package*.json ./

RUN --mount=type=cache,target=/root/.npm \
    npm install

COPY . .

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
    wget \
    curl \
    postgresql-client \
    redis \
    vim \
    procps \
    busybox-extras \
    && npm install -g pm2

# Criar usuário não-root
RUN addgroup -g 1001 -S appuser && \
    adduser -u 1001 -S appuser -G appuser

# Copiar apenas os arquivos necessários
COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/package.json ./package.json

# Criar diretórios para mídia e definir permissões
RUN mkdir -p /usr/src/app/public && \
    mkdir -p /usr/src/app/uploads && \
    mkdir -p /usr/src/app/private && \
    mkdir -p /usr/src/app/logs && \
    mkdir -p /usr/src/app/config && \
    chown -R appuser:appuser /usr/src/app && \
    chmod -R 755 /usr/src/app

# Copiar arquivos públicos do build
COPY --from=build --chown=appuser:appuser /usr/src/app/public ./public

# Copiar script de preparação para migrações
COPY --chown=appuser:appuser --from=build /usr/src/app/prepare-migrations.js ./prepare-migrations.js

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
HEALTHCHECK --interval=30s --timeout=30s --start-period=220s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Mudar para o usuário não-root
USER appuser

# Criar script de inicialização
COPY --chown=appuser:appuser <<EOF /usr/src/app/start.sh
#!/bin/bash

# Define log function
log() {
    echo -e "[INFO] \$1"
}

# Verificar conexão com o banco de dados
log "Verificando conexão com o banco de dados..."
log "DATABASE_URL: \${DATABASE_URL}"

# Extrair informações do banco de dados usando expressões mais simples
if [ -n "\$DATABASE_URL" ]; then
  # Exemplo: postgres://user:password@host:port/dbname
  DB_USER=\$(echo "\$DATABASE_URL" | awk -F '//' '{print \$2}' | awk -F ':' '{print \$1}')
  DB_PASS=\$(echo "\$DATABASE_URL" | awk -F ':' '{print \$3}' | awk -F '@' '{print \$1}')
  DB_HOST=\$(echo "\$DATABASE_URL" | awk -F '@' '{print \$2}' | awk -F ':' '{print \$1}')
  DB_PORT=\$(echo "\$DATABASE_URL" | awk -F ':' '{print \$4}' | awk -F '/' '{print \$1}')
  DB_NAME=\$(echo "\$DATABASE_URL" | awk -F '/' '{print \$NF}')
  
  log "Informações extraídas:"
  log "Host: \$DB_HOST"
  log "Porta: \$DB_PORT"
  log "Usuário: \$DB_USER"
  log "Banco: \$DB_NAME"
  
  # Tentar conexão com o banco
  export PGPASSWORD=\$DB_PASS
  until psql -h "\$DB_HOST" -p "\$DB_PORT" -U "\$DB_USER" -c '\q'; do
    log "Banco de dados não está disponível ainda - aguardando..."
    sleep 3
  done
  log "Conexão com o banco de dados estabelecida com sucesso!"
else
  log "ERRO: Variável DATABASE_URL não definida"
  exit 1
fi

# Preparar configuração para migrações
log "Preparando configuração para migrações..."
node prepare-migrations.js
if [ \$? -ne 0 ]; then
  log "ERRO: Falha ao preparar configuração para migrações"
  exit 1
fi
log "Configuração para migrações preparada com sucesso"

# Executar migrações
log "Iniciando execução das migrações do banco de dados..."
npm run db:migrate
if [ \$? -ne 0 ]; then
  log "ERRO: Falha ao executar migrações"
  exit 1
fi
log "Migrações executadas com sucesso!"

# Iniciar aplicação
log "Iniciando a aplicação com PM2..."
pm2-runtime start ecosystem.config.js
EOF

RUN chmod +x /usr/src/app/start.sh

# Iniciar a aplicação
CMD ["/usr/src/app/start.sh"]
