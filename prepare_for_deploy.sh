#!/bin/bash

# Script para preparar o projeto para deploy no Coolify
# Este script verifica e copia os arquivos necessários para garantir um deploy bem-sucedido

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

# Verificar se estamos no diretório raiz do projeto
if [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    error "Este script deve ser executado no diretório raiz do projeto TicketZap."
    exit 1
fi

echo "Preparando projeto para deploy no Coolify..."

# Verificar e copiar start.sh para o diretório backend
if [ -f "start.sh" ]; then
    if [ -f "backend/start.sh" ]; then
        warning "O arquivo start.sh já existe no diretório backend. Deseja sobrescrevê-lo? (s/n)"
        read -r resposta
        if [[ $resposta =~ ^[Ss]$ ]]; then
            cp start.sh backend/
            success "Arquivo start.sh copiado para o diretório backend."
        else
            warning "Mantendo o arquivo start.sh existente no diretório backend."
        fi
    else
        cp start.sh backend/
        success "Arquivo start.sh copiado para o diretório backend."
    fi
    
    # Verificar permissões do arquivo start.sh
    chmod +x backend/start.sh
    success "Permissões de execução definidas para backend/start.sh."
else
    error "Arquivo start.sh não encontrado no diretório raiz."
    exit 1
fi

# Verificar e copiar create_tables.sql para o diretório backend
if [ -f "create_tables.sql" ]; then
    if [ -f "backend/create_tables.sql" ]; then
        warning "O arquivo create_tables.sql já existe no diretório backend. Deseja sobrescrevê-lo? (s/n)"
        read -r resposta
        if [[ $resposta =~ ^[Ss]$ ]]; then
            cp create_tables.sql backend/
            success "Arquivo create_tables.sql copiado para o diretório backend."
        else
            warning "Mantendo o arquivo create_tables.sql existente no diretório backend."
        fi
    else
        cp create_tables.sql backend/
        success "Arquivo create_tables.sql copiado para o diretório backend."
    fi
else
    error "Arquivo create_tables.sql não encontrado no diretório raiz."
    exit 1
fi

# Verificar se o Dockerfile está usando os arquivos copiados
if grep -q "COPY --chown=appuser:appuser start.sh /usr/src/app/start.sh" backend/Dockerfile && \
   grep -q "COPY --chown=appuser:appuser create_tables.sql /usr/src/app/create_tables.sql" backend/Dockerfile; then
    success "Dockerfile está configurado corretamente para usar os arquivos copiados."
else
    warning "O Dockerfile pode não estar configurado corretamente para usar os arquivos copiados."
    echo "Verifique se as seguintes linhas estão presentes no Dockerfile:"
    echo "COPY --chown=appuser:appuser start.sh /usr/src/app/start.sh"
    echo "COPY --chown=appuser:appuser create_tables.sql /usr/src/app/create_tables.sql"
    echo "RUN chmod +x /usr/src/app/start.sh"
fi

# Verificar .dockerignore
if [ -f "backend/.dockerignore" ]; then
    success "Arquivo .dockerignore encontrado no diretório backend."
else
    warning "Arquivo .dockerignore não encontrado no diretório backend. Criando arquivo padrão..."
    cat > backend/.dockerignore << EOF
node_modules
.env*
dist
npm-debug.log
yarn-debug.log
yarn-error.log
.git
.github
.gitignore
*.md
*.log
*.swp
.DS_Store
.vscode
.idea
coverage
tests
__tests__
*.test.js
*.spec.js
docs
tmp
logs
EOF
    success "Arquivo .dockerignore criado no diretório backend."
fi

echo ""
success "Preparação concluída! O projeto está pronto para deploy no Coolify."
echo "Lembre-se de configurar as seguintes variáveis de ambiente no Coolify:"
echo "- DATABASE_URL: URL de conexão com o PostgreSQL"
echo "- REDIS_URI: URL de conexão com o Redis"
echo "- JWT_SECRET e JWT_REFRESH_SECRET: Segredos para tokens JWT"
echo "- NODE_ENV: Definido como 'production'"
echo "- PORT: Porta em que a aplicação irá executar"
echo "- UPLOAD_DIR, PUBLIC_DIR, PRIVATE_DIR: Diretórios para armazenamento de arquivos"
echo ""
echo "Para iniciar o deploy, execute o comando de build no Coolify."
