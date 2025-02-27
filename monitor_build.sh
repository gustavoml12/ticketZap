#!/bin/bash

# Script para monitorar o processo de build do Docker
# Uso: ./monitor_build.sh <container_id_ou_nome>

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

if [ -z "$1" ]; then
    echo -e "${RED}Erro: Forneça o ID ou nome do container como argumento.${NC}"
    echo "Uso: ./monitor_build.sh <container_id_ou_nome>"
    exit 1
fi

CONTAINER=$1

echo -e "${GREEN}Iniciando monitoramento do container ${YELLOW}$CONTAINER${NC}"
echo "Pressione Ctrl+C para sair"
echo

# Função para mostrar estatísticas do container
show_stats() {
    echo -e "\n${YELLOW}=== Estatísticas do Container ===${NC}"
    docker stats --no-stream $CONTAINER
    
    echo -e "\n${YELLOW}=== Processos em Execução ===${NC}"
    docker exec $CONTAINER ps aux || echo -e "${RED}Não foi possível executar 'ps' no container${NC}"
    
    echo -e "\n${YELLOW}=== Uso de Disco ===${NC}"
    docker exec $CONTAINER df -h || echo -e "${RED}Não foi possível verificar o uso de disco${NC}"
    
    echo -e "\n${YELLOW}=== Logs Recentes ===${NC}"
    docker logs --tail 20 $CONTAINER
}

# Loop principal
while true; do
    clear
    echo -e "${GREEN}Monitorando container ${YELLOW}$CONTAINER${NC} - $(date)"
    
    # Verificar se o container ainda existe
    if ! docker ps | grep -q $CONTAINER; then
        if docker ps -a | grep -q $CONTAINER; then
            echo -e "${RED}O container parou de executar.${NC}"
            echo -e "Status final:"
            docker ps -a | grep $CONTAINER
            echo -e "\nÚltimas linhas do log:"
            docker logs --tail 50 $CONTAINER
            exit 1
        else
            echo -e "${RED}Container não encontrado.${NC}"
            exit 1
        fi
    fi
    
    # Mostrar estatísticas
    show_stats
    
    # Aguardar antes da próxima atualização
    sleep 10
done
