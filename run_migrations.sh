#!/bin/bash

# Script para executar migrações no container do backend

# Verificar se o container está rodando
echo "Verificando se o container do backend está rodando..."
CONTAINER_ID=$(docker ps | grep backend | awk '{print $1}')

if [ -z "$CONTAINER_ID" ]; then
  echo "Container do backend não encontrado. Verifique se o serviço está rodando."
  exit 1
fi

echo "Container do backend encontrado: $CONTAINER_ID"

# Copiar o arquivo de configuração para o container
echo "Copiando arquivo de configuração para o container..."
docker cp sequelize-config.json $CONTAINER_ID:/usr/src/app/config/config.json

# Executar as migrações
echo "Executando migrações..."
docker exec -it $CONTAINER_ID bash -c "cd /usr/src/app && npx sequelize-cli db:migrate"

# Verificar o resultado
if [ $? -eq 0 ]; then
  echo "Migrações executadas com sucesso!"
  echo "Reiniciando o serviço..."
  docker exec -it $CONTAINER_ID bash -c "pm2 restart all"
  echo "Serviço reiniciado. Verifique os logs para confirmar o funcionamento."
else
  echo "Erro ao executar as migrações. Verifique os logs para mais detalhes."
fi

echo "Script concluído."
