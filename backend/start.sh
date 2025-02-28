#!/bin/bash

# Script para inicialização da aplicação TicketZap
# Este script verifica a conexão com o banco de dados, executa migrações e inicia a aplicação

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

log "Aguardando conexão com o PostgreSQL..."
until PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -c '\q'; do
    log "PostgreSQL não está disponível ainda - aguardando..."
    sleep 2
done

log "Conexão com PostgreSQL estabelecida."

# Verificar se o banco de dados existe, se não, criar
DB_EXISTS=$(PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -lqt | cut -d \| -f 1 | grep -w $DB_NAME)
if [ -z "$DB_EXISTS" ]; then
    log "Banco de dados $DB_NAME não existe. Criando..."
    PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -c "CREATE DATABASE \"$DB_NAME\";"
    log "Banco de dados $DB_NAME criado com sucesso."
fi

# Executar o script SQL para criar extensões e tabelas iniciais
log "Executando script SQL para criar extensões..."

# Verificar se todas as tabelas necessárias existem
REQUIRED_TABLES=("Companies" "Users" "Settings" "UserSocketSessions" "Whatsapps" "Contacts" "Queues" "Tickets" "Messages" "QueueOptions" "Plans" "Invoices" "Schedules")
MISSING_TABLES=false

for TABLE in "${REQUIRED_TABLES[@]}"; do
    if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tc "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = '$TABLE');" | grep -q t; then
        log "Tabela $TABLE não existe"
        MISSING_TABLES=true
    fi
done

if [ "$MISSING_TABLES" = true ]; then
    log "Algumas tabelas estão faltando. Criando todas as tabelas..."
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f /usr/src/app/create_tables.sql
else
    log "Todas as tabelas já existem"
fi

log "Executando migrações do Sequelize..."
cd /usr/src/app
npx sequelize-cli db:migrate

# Criar usuário admin padrão se as variáveis estiverem definidas
if [ ! -z "$ADMIN_EMAIL" ] && [ ! -z "$ADMIN_PASSWORD" ] && [ ! -z "$ADMIN_NAME" ]; then
    log "Criando usuário admin padrão..."
    cd /usr/src/app
    node -e "
        const { User } = require('./dist/models');
        const bcrypt = require('bcryptjs');
        
        async function createAdmin() {
            try {
                const existingAdmin = await User.findOne({ where: { email: process.env.ADMIN_EMAIL } });
                
                if (!existingAdmin) {
                    await User.create({
                        name: process.env.ADMIN_NAME,
                        email: process.env.ADMIN_EMAIL,
                        password: bcrypt.hashSync(process.env.ADMIN_PASSWORD, 10),
                        profile: 'admin',
                        active: true
                    });
                    console.log('Usuário admin criado com sucesso.');
                } else {
                    console.log('Usuário admin já existe.');
                }
            } catch (error) {
                console.error('Erro ao criar usuário admin:', error);
            }
        }
        
        createAdmin();
    "
fi

# Iniciar Redis em background
log "Iniciando Redis..."
redis-server --daemonize yes

# Verificar se o Redis está rodando
until redis-cli ping > /dev/null 2>&1; do
    log "Aguardando Redis iniciar..."
    sleep 1
done
log "Redis está rodando."

# Criar arquivo de health check
log "Criando arquivo de health check..."
mkdir -p /usr/src/app/public
touch /usr/src/app/public/health-check

# Iniciar servidor Node.js
log "Iniciando servidor Node.js..."
if [ "$NODE_ENV" = "production" ]; then
    log "Modo de produção detectado. Usando PM2 para gerenciar o processo."

    # Verificar se o arquivo server.js existe
    if [ ! -f "/usr/src/app/dist/server.js" ]; then
        error "Arquivo server.js não encontrado em /usr/src/app/dist/"
        ls -la /usr/src/app/dist/
        exit 1
    fi

    # Iniciar com PM2
    exec pm2-runtime start /usr/src/app/dist/server.js
else
    log "Modo de desenvolvimento detectado. Iniciando com Node."
    cd /usr/src/app
    node dist/index.js
fi
