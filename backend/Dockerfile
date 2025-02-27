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

RUN apk add --no-cache wget curl postgresql-client redis && \
    npm install -g pm2

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
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget --spider -q http://localhost:3000/health || exit 1

# Mudar para o usuário não-root
USER appuser

# Criar script de inicialização
COPY --chown=appuser:appuser <<EOF /usr/src/app/start.sh
#!/bin/sh
echo "Criando diretório de configuração..."
mkdir -p /usr/src/app/config

echo "Criando arquivo de configuração do Sequelize..."
cat > /usr/src/app/config/config.json << 'CONFIGJSON'
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
CONFIGJSON

# Extrair informações da string de conexão DATABASE_URL
DB_HOST=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/[^:]*:[^@]*@\([^:]*\):.*/\1/p')
DB_PORT=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/[^:]*:[^@]*@[^:]*:\([^/]*\)\/.*/\1/p')
DB_USER=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/\([^:]*\):.*/\1/p')
DB_NAME=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/[^:]*:[^@]*@[^:]*:[^/]*\/\(.*\)$/\1/p')

echo "Verificando conexão com o banco de dados..."
# Aguardar até que o banco de dados esteja disponível
max_retries=30
counter=0
until PGPASSWORD=${DATABASE_URL#*:*:} psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT 1" > /dev/null 2>&1
do
    counter=$((counter+1))
    if [ $counter -ge $max_retries ]; then
        echo "Não foi possível conectar ao banco de dados após $max_retries tentativas."
        exit 1
    fi
    echo "Aguardando conexão com o banco de dados... ($counter/$max_retries)"
    sleep 2
done

echo "Conexão com o banco de dados estabelecida."

# Verificar se a tabela Settings já existe
echo "Verificando se as tabelas já existem..."
TABLE_EXISTS=$(PGPASSWORD=${DATABASE_URL#*:*:} psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'Settings')")

if [[ $TABLE_EXISTS == *"t"* ]]; then
    echo "Tabela Settings já existe. Pulando a criação de tabelas."
else
    echo "Tabela Settings não encontrada. Executando migrações..."
    cd /usr/src/app
    npx sequelize-cli db:migrate
    echo "Migrações concluídas."
fi

echo "Iniciando a aplicação..."
pm2-runtime start ecosystem.config.js
EOF

RUN chmod +x /usr/src/app/start.sh

# Iniciar a aplicação
CMD ["/usr/src/app/start.sh"]
