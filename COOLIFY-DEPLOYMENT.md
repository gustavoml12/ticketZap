# Implantação no Coolify

Este guia descreve como implantar a aplicação TicketZap no Coolify, separando o frontend e o backend em serviços distintos e utilizando serviços externos para PostgreSQL e Redis.

## Pré-requisitos

- Acesso ao Coolify
- Serviços PostgreSQL e Redis já configurados:
  - PostgreSQL: `postgres://postgres:sBRFcX3M3z6SY0W5V6Jz42yzBOlM4qiBDXx9pkcoRb1qOTvuF0KdxF8M3YuGwpsJ@u80ggksoo4k40ccwsg8ww4k0:5432/postgres`
  - Redis: `redis://default:gTLgFjDx9Vs5MExecw5codEFcVp068VrCH6pdqMt0PouhC2W0piy8RIBjN5CBnwo@qogoksgwc4kk8cswc0g488w8:6379/0`

## Estrutura de Arquivos

Os seguintes arquivos foram criados ou modificados para facilitar a implantação:

- `backend/Dockerfile.coolify`: Dockerfile otimizado para o backend
- `frontend/Dockerfile.coolify`: Dockerfile otimizado para o frontend
- `frontend/nginx/coolify.conf`: Configuração do Nginx para o frontend
- `backend-env-example.txt`: Exemplo de variáveis de ambiente para o backend
- `frontend-env-example.txt`: Exemplo de variáveis de ambiente para o frontend

## Passos para Implantação

### 1. Backend

1. No Coolify, crie um novo serviço para o backend:
   - Tipo: Dockerfile
   - Caminho do Dockerfile: `backend/Dockerfile`
   - Porta: 3000

2. Configure as variáveis de ambiente para o backend:
   ```
   DATABASE_URL=postgres://postgres:sBRFcX3M3z6SY0W5V6Jz42yzBOlM4qiBDXx9pkcoRb1qOTvuF0KdxF8M3YuGwpsJ@u80ggksoo4k40ccwsg8ww4k0:5432/postgres
   REDIS_URI=redis://default:gTLgFjDx9Vs5MExecw5codEFcVp068VrCH6pdqMt0PouhC2W0piy8RIBjN5CBnwo@qogoksgwc4kk8cswc0g488w8:6379/0
   JWT_SECRET=ticket
   JWT_REFRESH_SECRET=ticket-refresh
   NODE_ENV=production
   PORT=3000
   UPLOAD_DIR=/usr/src/app/uploads
   PUBLIC_DIR=/usr/src/app/public
   PRIVATE_DIR=/usr/src/app/private
   ```

3. (Opcional) Configure variáveis de ambiente adicionais para personalizar o usuário administrador:
   ```
   ADMIN_EMAIL=admin@exemplo.com
   ADMIN_PASSWORD=senha_segura
   ADMIN_NAME=Administrador
   ```

4. Configure volumes persistentes para o backend:
   - `/usr/src/app/uploads`: Para armazenar uploads de arquivos
   - `/usr/src/app/public`: Para arquivos públicos
   - `/usr/src/app/private`: Para arquivos privados
   - `/usr/src/app/logs`: Para logs da aplicação

### 2. Frontend

1. No Coolify, crie um novo serviço para o frontend:
   - Tipo: Dockerfile
   - Caminho do Dockerfile: `frontend/Dockerfile.coolify`
   - Porta: 80

2. Configure as variáveis de ambiente para o frontend:
   ```
   REACT_APP_BACKEND_URL=/api
   NODE_ENV=production
   DISABLE_ESLINT_PLUGIN=true
   GENERATE_SOURCEMAP=false
   CI=false
   NODE_OPTIONS=--max-old-space-size=2048
   ```

3. Configure volumes persistentes para o frontend (opcional):
   - `/usr/src/app/uploads`: Para compartilhar uploads com o backend

### 3. Configuração de Rede

1. Certifique-se de que o frontend e o backend estejam na mesma rede para que possam se comunicar.
2. Configure o proxy reverso no Coolify para direcionar o tráfego para o frontend.

### 4. Configuração de Domínio

1. Configure seu domínio para apontar para o serviço do frontend.
2. Se necessário, configure certificados SSL para seu domínio.

## Processo de Inicialização e Migração do Banco de Dados

O backend inclui um script de inicialização (`start.sh`) que automatiza o processo de verificação e configuração do banco de dados. Este script realiza as seguintes etapas:

1. **Verificação de Conexão**: Verifica se o PostgreSQL está acessível usando as credenciais fornecidas em `DATABASE_URL`.

2. **Criação do Banco de Dados**: Se o banco de dados especificado não existir, o script tentará criá-lo automaticamente.

3. **Instalação de Extensões**: Verifica e instala as extensões PostgreSQL necessárias (`unaccent` e `uuid-ossp`).

4. **Migração de Tabelas**: Verifica se as tabelas essenciais existem e, caso não existam, executa as migrações do Sequelize.

5. **Criação de Usuário Administrador**: Se não houver um usuário administrador, cria um usuário padrão (a menos que variáveis de ambiente específicas sejam fornecidas para personalizar o administrador).

Este processo garante que o banco de dados seja configurado corretamente na primeira inicialização, sem necessidade de intervenção manual.

### Solução de Problemas

Se o deploy falhar devido a problemas com o banco de dados, verifique os logs do container para identificar o problema específico. Os problemas mais comuns incluem:

- **Falha na Conexão**: Verifique se a string de conexão `DATABASE_URL` está correta e se o PostgreSQL está acessível.
- **Permissões Insuficientes**: Verifique se o usuário PostgreSQL tem permissões para criar bancos de dados e extensões.
- **Falha nas Migrações**: Verifique os logs para erros específicos durante o processo de migração.

Para mais detalhes, consulte o arquivo `DEPLOY-INSTRUCTIONS.md`.

## Requisitos de Ambiente

Antes de iniciar o deploy no Coolify, certifique-se de que o repositório esteja corretamente configurado:

1. **Verifique a estrutura de arquivos**:
   
   Os seguintes arquivos devem estar presentes no diretório `backend/`:
   
   - `start.sh`: Script de inicialização que configura o banco de dados e inicia a aplicação
   - `create_tables.sql`: Script SQL para criação das tabelas essenciais
   
   Se estes arquivos não estiverem presentes, copie-os do diretório raiz:
   
   ```bash
   cp /caminho/para/SistemaAtendimento/start.sh /caminho/para/SistemaAtendimento/backend/
   cp /caminho/para/SistemaAtendimento/create_tables.sql /caminho/para/SistemaAtendimento/backend/
   ```

2. **Verifique o Dockerfile**:
   
   O Dockerfile no diretório `backend/` deve conter as instruções corretas para copiar os arquivos `start.sh` e `create_tables.sql`. Verifique se as seguintes linhas estão presentes:
   
   ```dockerfile
   # Copiar scripts de inicialização
   COPY --chown=appuser:appuser start.sh /usr/src/app/start.sh
   COPY --chown=appuser:appuser create_tables.sql /usr/src/app/create_tables.sql
   RUN chmod +x /usr/src/app/start.sh
   ```

3. **Verifique as permissões**:
   
   Certifique-se de que o arquivo `start.sh` tenha permissões de execução:
   
   ```bash
   chmod +x /caminho/para/SistemaAtendimento/backend/start.sh
   ```

## Verificação da Implantação

Após a implantação, verifique se:

1. O backend está respondendo em `/health`
2. O frontend está carregando corretamente
3. O frontend consegue se comunicar com o backend através do endpoint `/api`
4. As conexões WebSocket estão funcionando corretamente

## Solução de Problemas

Se encontrar problemas durante a implantação:

1. Verifique os logs do serviço no Coolify
2. Confirme se as variáveis de ambiente estão configuradas corretamente
3. Verifique se os serviços PostgreSQL e Redis estão acessíveis
4. Confirme se a rede entre os serviços está configurada corretamente

## Migração do Banco de Dados

Após a implantação do backend, você pode precisar executar migrações de banco de dados:

```bash
# Acesse o terminal do serviço backend no Coolify e execute:
npm run db:migrate
