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
   - Caminho do Dockerfile: `backend/Dockerfile.coolify`
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

3. Configure volumes persistentes para o backend:
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
```
