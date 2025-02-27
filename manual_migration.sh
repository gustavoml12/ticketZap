#!/bin/bash

# Script para executar manualmente as migrações no banco de dados
# Use este script apenas se as migrações automáticas não funcionarem

# Extrair informações da string de conexão DATABASE_URL
echo "Por favor, insira a string de conexão do banco de dados (DATABASE_URL):"
read DATABASE_URL

if [ -z "$DATABASE_URL" ]; then
  echo "String de conexão não fornecida. Saindo."
  exit 1
fi

# Extrair componentes da URL
DB_USER=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/\([^:]*\):.*/\1/p')
DB_PASS=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/[^:]*:\([^@]*\)@.*/\1/p')
DB_HOST=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/[^:]*:[^@]*@\([^:]*\):.*/\1/p')
DB_PORT=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/[^:]*:[^@]*@[^:]*:\([^/]*\)\/.*/\1/p')
DB_NAME=$(echo $DATABASE_URL | sed -n 's/^postgres:\/\/[^:]*:[^@]*@[^:]*:[^/]*\/\(.*\)$/\1/p')

echo "Conectando ao banco de dados PostgreSQL..."
echo "Host: $DB_HOST"
echo "Porta: $DB_PORT"
echo "Usuário: $DB_USER"
echo "Banco de dados: $DB_NAME"

# Verificar se a tabela Settings já existe
echo "Verificando se as tabelas já existem..."
TABLE_EXISTS=$(PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'Settings')")

if [[ $TABLE_EXISTS == *"t"* ]]; then
  echo "Tabela Settings já existe. Deseja continuar mesmo assim? (s/n)"
  read CONTINUE
  if [[ $CONTINUE != "s" ]]; then
    echo "Operação cancelada pelo usuário."
    exit 0
  fi
fi

# Executar o script SQL
echo "Executando o script SQL..."
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f create_tables.sql

# Verificar o resultado
if [ $? -eq 0 ]; then
  echo "Script SQL executado com sucesso!"
  
  # Perguntar se deseja criar um usuário administrador
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
    
    echo "Usuário administrador criado com sucesso!"
    echo "Email: admin@exemplo.com"
    echo "Senha: 123456"
  fi
  
  echo "Agora você pode reiniciar o serviço backend."
else
  echo "Erro ao executar o script SQL. Verifique os logs para mais detalhes."
fi

echo "Script concluído."
