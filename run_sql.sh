#!/bin/bash

# Script para executar o SQL diretamente no banco de dados PostgreSQL

# Extrair informações da string de conexão
# Formato: postgres://postgres:password@host:5432/postgres
DB_URL=$(grep DATABASE_URL backend-env-example.txt | cut -d= -f2-)

if [ -z "$DB_URL" ]; then
  echo "String de conexão do banco de dados não encontrada."
  echo "Por favor, forneça a string de conexão manualmente:"
  read -p "DATABASE_URL: " DB_URL
fi

# Extrair componentes da URL
DB_USER=$(echo $DB_URL | sed -n 's/^postgres:\/\/\([^:]*\):.*/\1/p')
DB_PASS=$(echo $DB_URL | sed -n 's/^postgres:\/\/[^:]*:\([^@]*\)@.*/\1/p')
DB_HOST=$(echo $DB_URL | sed -n 's/^postgres:\/\/[^:]*:[^@]*@\([^:]*\):.*/\1/p')
DB_PORT=$(echo $DB_URL | sed -n 's/^postgres:\/\/[^:]*:[^@]*@[^:]*:\([^/]*\)\/.*/\1/p')
DB_NAME=$(echo $DB_URL | sed -n 's/^postgres:\/\/[^:]*:[^@]*@[^:]*:[^/]*\/\(.*\)$/\1/p')

echo "Conectando ao banco de dados PostgreSQL..."
echo "Host: $DB_HOST"
echo "Porta: $DB_PORT"
echo "Usuário: $DB_USER"
echo "Banco de dados: $DB_NAME"

# Executar o script SQL
echo "Executando o script SQL..."
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f create_tables.sql

# Verificar o resultado
if [ $? -eq 0 ]; then
  echo "Script SQL executado com sucesso!"
  echo "Agora você pode reiniciar o serviço backend."
else
  echo "Erro ao executar o script SQL. Verifique os logs para mais detalhes."
fi

echo "Script concluído."
