#!/bin/bash

# Script para verificar o estado do banco de dados e diagnosticar problemas
# Autor: Cascade AI
# Data: $(date +%Y-%m-%d)

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

# Verificar se a variável DATABASE_URL foi fornecida
if [ -z "$DATABASE_URL" ]; then
    echo "Por favor, insira a string de conexão do banco de dados (DATABASE_URL):"
    read DATABASE_URL
fi

if [ -z "$DATABASE_URL" ]; then
    error "String de conexão não fornecida. Saindo."
    exit 1
fi

# Extrair componentes da URL
DB_USER=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/\([^:]*\):.*/\1/p')
DB_PASS=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/[^:]*:\([^@]*\)@.*/\1/p')
DB_HOST=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/[^:]*:[^@]*@\([^:]*\):.*/\1/p')
DB_PORT=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/[^:]*:[^@]*@[^:]*:\([^/]*\)\/.*/\1/p')
DB_NAME=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/[^:]*:[^@]*@[^:]*:[^/]*\/\(.*\)$/\1/p')

echo "Verificando conexão com o banco de dados PostgreSQL..."
echo "Host: $DB_HOST"
echo "Porta: $DB_PORT"
echo "Usuário: $DB_USER"
echo "Banco de dados: $DB_NAME"

# Verificar se o PostgreSQL está acessível
if ! command -v pg_isready &> /dev/null; then
    error "Comando pg_isready não encontrado. Verifique se o cliente PostgreSQL está instalado."
    exit 1
fi

# Verificar conexão com o banco de dados
pg_isready -h $DB_HOST -p $DB_PORT -U $DB_USER > /dev/null 2>&1
if [ $? -ne 0 ]; then
    error "Não foi possível conectar ao servidor PostgreSQL. Verifique se o serviço está em execução e acessível."
    exit 1
fi

success "Servidor PostgreSQL está acessível."

# Verificar se é possível fazer login no banco de dados
echo "Verificando autenticação no banco de dados..."
if ! PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT 1" > /dev/null 2>&1; then
    error "Falha na autenticação. Verifique as credenciais do banco de dados."
    exit 1
fi

success "Autenticação bem-sucedida."

# Verificar tabelas essenciais
echo "Verificando tabelas essenciais no banco de dados..."
ESSENTIAL_TABLES=("Settings" "Users" "Companies" "Tickets" "Contacts" "Messages")
MISSING_TABLES=()

for TABLE in "${ESSENTIAL_TABLES[@]}"; do
    TABLE_EXISTS=$(PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = '$TABLE')")
    
    if ! echo "$TABLE_EXISTS" | grep -q "t"; then
        MISSING_TABLES+=("$TABLE")
    fi
done

if [ ${#MISSING_TABLES[@]} -eq 0 ]; then
    success "Todas as tabelas essenciais existem no banco de dados."
else
    warning "As seguintes tabelas essenciais estão faltando: ${MISSING_TABLES[*]}"
    
    echo "Deseja executar as migrações para criar as tabelas faltantes? (s/n)"
    read EXECUTE_MIGRATIONS
    
    if [[ $EXECUTE_MIGRATIONS == "s" ]]; then
        echo "Escolha o método de migração:"
        echo "1. Usar Sequelize (npx sequelize-cli db:migrate)"
        echo "2. Executar script SQL (create_tables.sql)"
        read MIGRATION_METHOD
        
        if [[ $MIGRATION_METHOD == "1" ]]; then
            echo "Executando migrações com Sequelize..."
            # Verificar se estamos em um ambiente Docker
            if [ -f "/.dockerenv" ]; then
                cd /usr/src/app
                npx sequelize-cli db:migrate
            else
                # Assumindo que estamos no diretório raiz do projeto
                cd backend
                npx sequelize-cli db:migrate
            fi
            
            if [ $? -eq 0 ]; then
                success "Migrações executadas com sucesso."
            else
                error "Falha ao executar migrações com Sequelize."
            fi
        elif [[ $MIGRATION_METHOD == "2" ]]; then
            echo "Executando script SQL..."
            PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f create_tables.sql
            
            if [ $? -eq 0 ]; then
                success "Script SQL executado com sucesso."
            else
                error "Falha ao executar script SQL."
            fi
        else
            error "Opção inválida."
        fi
    else
        echo "Migrações não executadas."
    fi
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
    
    echo "Deseja instalar as extensões faltantes? (s/n)"
    read INSTALL_EXTENSIONS
    
    if [[ $INSTALL_EXTENSIONS == "s" ]]; then
        for EXT in "${MISSING_EXTENSIONS[@]}"; do
            echo "Instalando extensão $EXT..."
            PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "CREATE EXTENSION IF NOT EXISTS \"$EXT\";"
            
            if [ $? -eq 0 ]; then
                success "Extensão $EXT instalada com sucesso."
            else
                error "Falha ao instalar extensão $EXT."
            fi
        done
    else
        echo "Extensões não instaladas."
    fi
fi

# Verificar usuário administrador
echo "Verificando se existe um usuário administrador..."
ADMIN_EXISTS=$(PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT EXISTS (SELECT 1 FROM \"Users\" WHERE \"profile\" = 'admin')")

if echo "$ADMIN_EXISTS" | grep -q "t"; then
    success "Pelo menos um usuário administrador existe no sistema."
else
    warning "Nenhum usuário administrador encontrado."
    
    echo "Deseja criar um usuário administrador? (s/n)"
    read CREATE_ADMIN
    
    if [[ $CREATE_ADMIN == "s" ]]; then
        echo "Criando usuário administrador..."
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
            success "Usuário administrador criado com sucesso!"
            echo "Email: admin@exemplo.com"
            echo "Senha: 123456"
        else
            error "Falha ao criar usuário administrador."
        fi
    else
        echo "Usuário administrador não criado."
    fi
fi

echo "Verificação do banco de dados concluída."
