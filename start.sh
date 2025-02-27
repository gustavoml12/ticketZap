#!/bin/bash

# Script para inicialização da aplicação TicketZap
# Este script verifica a conexão com o banco de dados, cria o banco se necessário,
# executa migrações e inicia a aplicação

# Cores para melhor visualização
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Função para exibir mensagens de erro
error() {
    echo -e "${RED}ERRO:${NC} $1"
}

# Função para exibir mensagens de sucesso
success() {
    echo -e "${GREEN}SUCESSO:${NC} $1"
}

# Função para exibir mensagens de aviso
warning() {
    echo -e "${YELLOW}AVISO:${NC} $1"
}

# Verificar se a variável DATABASE_URL está definida
if [ -z "$DATABASE_URL" ]; then
    error "DATABASE_URL não está definida. Esta variável é obrigatória."
    exit 1
fi

echo "Verificando conexão com o banco de dados PostgreSQL..."

# Extrair componentes da URL
DB_USER=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/\([^:]*\):.*/\1/p')
DB_PASS=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/[^:]*:\([^@]*\)@.*/\1/p')
DB_HOST=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/[^:]*:[^@]*@\([^:]*\):.*/\1/p')
DB_PORT=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/[^:]*:[^@]*@[^:]*:\([^/]*\)\/.*/\1/p')
DB_NAME=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/[^:]*:[^@]*@[^:]*:[^/]*\/\(.*\)$/\1/p')

echo "Host: $DB_HOST"
echo "Porta: $DB_PORT"
echo "Usuário: $DB_USER"
echo "Banco de dados: $DB_NAME"

# Aguardar até que o servidor PostgreSQL esteja disponível
max_retries=30
counter=0

until pg_isready -h $DB_HOST -p $DB_PORT -U $DB_USER > /dev/null 2>&1
do
    counter=$((counter+1))
    if [ $counter -ge $max_retries ]; then
        error "Não foi possível conectar ao servidor PostgreSQL após $max_retries tentativas."
        error "Verifique se o serviço PostgreSQL está em execução e acessível."
        exit 1
    fi
    echo "Aguardando conexão com o servidor PostgreSQL... ($counter/$max_retries)"
    sleep 2
done

success "Servidor PostgreSQL está acessível."

# Verificar se é possível fazer login no banco de dados
echo "Verificando autenticação no banco de dados..."
if ! PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "SELECT 1" > /dev/null 2>&1; then
    error "Falha na autenticação. Verifique as credenciais do banco de dados."
    exit 1
fi

success "Autenticação bem-sucedida."

# Verificar se o banco de dados existe
echo "Verificando se o banco de dados '$DB_NAME' existe..."
DB_EXISTS=$(PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -t -c "SELECT EXISTS (SELECT 1 FROM pg_database WHERE datname = '$DB_NAME')")

if ! echo "$DB_EXISTS" | grep -q "t"; then
    warning "Banco de dados '$DB_NAME' não existe. Criando..."
    PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "CREATE DATABASE \"$DB_NAME\";"
    
    if [ $? -eq 0 ]; then
        success "Banco de dados '$DB_NAME' criado com sucesso."
    else
        error "Falha ao criar o banco de dados '$DB_NAME'."
        exit 1
    fi
else
    success "Banco de dados '$DB_NAME' já existe."
fi

# Verificar extensões PostgreSQL necessárias
echo "Verificando extensões PostgreSQL necessárias..."
REQUIRED_EXTENSIONS=("unaccent" "uuid-ossp")
MISSING_EXTENSIONS=()

for EXT in "${REQUIRED_EXTENSIONS[@]}"; do
    EXT_EXISTS=$(PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT EXISTS (SELECT 1 FROM pg_extension WHERE extname = '$EXT')")
    
    if ! echo "$EXT_EXISTS" | grep -q "t"; then
        MISSING_EXTENSIONS+=("$EXT")
    fi
done

if [ ${#MISSING_EXTENSIONS[@]} -eq 0 ]; then
    success "Todas as extensões necessárias estão instaladas."
else
    warning "As seguintes extensões estão faltando: ${MISSING_EXTENSIONS[*]}"
    
    for EXT in "${MISSING_EXTENSIONS[@]}"; do
        echo "Instalando extensão $EXT..."
        PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "CREATE EXTENSION IF NOT EXISTS \"$EXT\";"
        
        if [ $? -eq 0 ]; then
            success "Extensão $EXT instalada com sucesso."
        else
            warning "Falha ao instalar extensão $EXT. A aplicação pode não funcionar corretamente."
        fi
    done
fi

# Verificar tabelas essenciais
echo "Verificando tabelas essenciais no banco de dados..."
TABLE_EXISTS=$(PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'Settings')")

if echo "$TABLE_EXISTS" | grep -q "t"; then
    echo "Tabela Settings já existe. Verificando outras tabelas essenciais..."
    
    # Verificar outras tabelas essenciais
    USERS_EXISTS=$(PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'Users')")
    COMPANIES_EXISTS=$(PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'Companies')")
    
    if echo "$USERS_EXISTS" | grep -q "t" && echo "$COMPANIES_EXISTS" | grep -q "t"; then
        success "Todas as tabelas essenciais existem. Pulando a criação de tabelas."
    else
        warning "Algumas tabelas essenciais estão faltando. Executando migrações..."
        cd /usr/src/app
        npx sequelize-cli db:migrate
        
        if [ $? -eq 0 ]; then
            success "Migrações concluídas com sucesso."
        else
            warning "Falha ao executar migrações com Sequelize. Tentando script SQL alternativo..."
            PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f /usr/src/app/create_tables.sql
            
            if [ $? -eq 0 ]; then
                success "Script SQL executado com sucesso."
            else
                error "Falha ao executar script SQL. A aplicação pode não funcionar corretamente."
            fi
        fi
    fi
else
    warning "Tabela Settings não encontrada. Executando migrações..."
    cd /usr/src/app
    npx sequelize-cli db:migrate
    
    if [ $? -ne 0 ]; then
        warning "Falha ao executar migrações automáticas. Tentando script SQL alternativo..."
        PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f /usr/src/app/create_tables.sql
        
        if [ $? -eq 0 ]; then
            success "Script SQL executado com sucesso."
        else
            error "Falha ao executar script SQL. A aplicação pode não funcionar corretamente."
        fi
    else
        success "Migrações concluídas com sucesso."
    fi
fi

# Verificar usuário administrador
echo "Verificando se existe um usuário administrador..."
ADMIN_EXISTS=$(PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT EXISTS (SELECT 1 FROM \"Users\" WHERE \"profile\" = 'admin')")

if echo "$ADMIN_EXISTS" | grep -q "t"; then
    success "Pelo menos um usuário administrador existe no sistema."
else
    warning "Nenhum usuário administrador encontrado. Criando usuário administrador padrão..."
    
    # Verificar se as variáveis de ambiente para o admin estão definidas
    if [ -n "$ADMIN_EMAIL" ] && [ -n "$ADMIN_PASSWORD" ] && [ -n "$ADMIN_NAME" ]; then
        echo "Usando variáveis de ambiente para criar usuário administrador..."
        # Aqui você pode implementar a lógica para criar o admin com as variáveis fornecidas
    else
        echo "Criando usuário administrador padrão..."
        PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
        INSERT INTO \"Users\" (
          \"name\", 
          \"email\", 
          \"passwordHash\", 
          \"createdAt\", 
          \"updatedAt\", 
          \"profile\", 
          \"companyId\", 
          \"super\"
        ) VALUES (
          'Admin', 
          'admin@exemplo.com', 
          '\$2a\$08\$WaEmpmFDD/XkDqorkqY1ZOIGGAMkxS0ixY1vWky4nFCVORQvMgmwi', -- senha: 123456
          NOW(), 
          NOW(), 
          'admin', 
          1, 
          true
        ) ON CONFLICT (\"email\") DO NOTHING;"
        
        if [ $? -eq 0 ]; then
            success "Usuário administrador padrão criado com sucesso!"
            echo "Email: admin@exemplo.com"
            echo "Senha: 123456"
        else
            warning "Falha ao criar usuário administrador padrão."
        fi
    fi
fi

echo "Iniciando a aplicação..."
cd /usr/src/app
pm2-runtime start ecosystem.config.js
