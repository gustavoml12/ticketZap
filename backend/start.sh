#!/bin/bash

# Script para inicialização da aplicação TicketZap
# Este script verifica a conexão com o banco de dados e inicia a aplicação

# Cores para melhor visualização
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Função para exibir mensagens
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para lidar com sinais de término
cleanup() {
    log "Encerrando aplicação..."
    exit 0
}

# Registrar handlers para sinais
trap cleanup SIGINT SIGTERM

# Verificar variáveis de ambiente obrigatórias
if [ -z "$DATABASE_URL" ]; then
    error "DATABASE_URL não está definida. Esta variável é obrigatória."
    exit 1
fi

log "Iniciando aplicação TicketZap..."

# Extrair componentes da URL
DB_USER=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/\([^:]*\):.*/\1/p')
DB_PASS=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/[^:]*:\([^@]*\)@.*/\1/p')
DB_HOST=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/[^:]*:[^@]*@\([^:]*\):.*/\1/p')
DB_PORT=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/[^:]*:[^@]*@[^:]*:\([^/]*\)\/.*/\1/p')
DB_NAME=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/[^:]*:[^@]*@[^:]*:[^/]*\/\(.*\)$/\1/p')

log "Verificando conexão com o PostgreSQL..."
until PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -c '\q'; do
    log "PostgreSQL não está disponível ainda - aguardando..."
    sleep 2
done

log "Conexão com PostgreSQL estabelecida."

# Executar migrations e seeds
log "Executando migrations..."
cd /usr/src/app
npx sequelize-cli db:migrate
if [ $? -eq 0 ]; then
    log "Migrations executadas com sucesso."
else
    error "Erro ao executar migrations."
    exit 1
fi

log "Executando seeds..."
npx sequelize-cli db:seed:all
if [ $? -eq 0 ]; then
    log "Seeds executados com sucesso."
else
    error "Erro ao executar seeds."
    exit 1
fi

# Iniciar servidor Node.js
log "Iniciando servidor Node.js..."
if [ "$NODE_ENV" = "production" ]; then
    log "Modo de produção detectado. Usando PM2 para gerenciar o processo."
    pm2 start ecosystem.config.js --no-daemon
else
    log "Modo de desenvolvimento detectado. Iniciando com Node."
    node dist/server.js
fi
