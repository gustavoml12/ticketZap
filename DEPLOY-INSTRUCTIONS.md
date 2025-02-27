# Instruções para Deploy do TicketZap com Coolify

Este documento contém instruções detalhadas para o deploy do TicketZap utilizando a plataforma Coolify.

## Pré-requisitos

- Acesso à plataforma Coolify
- PostgreSQL e Redis configurados e acessíveis
- String de conexão do PostgreSQL e Redis

## Configuração do Ambiente

### Variáveis de Ambiente Obrigatórias para o Backend

```
# Database
DATABASE_URL=postgres://postgres:sBRFcX3M3z6SY0W5V6Jz42yzBOlM4qiBDXx9pkcoRb1qOTvuF0KdxF8M3YuGwpsJ@u80ggksoo4k40ccwsg8ww4k0:5432/postgres

# Redis
REDIS_URI=redis://default:gTLgFjDx9Vs5MExecw5codEFcVp068VrCH6pdqMt0PouhC2W0piy8RIBjN5CBnwo@qogoksgwc4kk8cswc0g488w8:6379/0

# JWT
JWT_SECRET=ticket
JWT_REFRESH_SECRET=ticket-refresh

# App
NODE_ENV=production
PORT=3000

# Directories
UPLOAD_DIR=/usr/src/app/uploads
PUBLIC_DIR=/usr/src/app/public
PRIVATE_DIR=/usr/src/app/private

# Frontend URL - Ajuste conforme necessário
FRONTEND_URL=https://seu-dominio.com.br
```

### Variáveis de Ambiente Opcionais para o Backend

```
# Admin padrão (opcional - será criado automaticamente se não existir)
ADMIN_EMAIL=admin@exemplo.com
ADMIN_PASSWORD=123456
ADMIN_NAME=Administrador

# SMTP (opcional - para envio de emails)
MAIL_HOST=smtp.exemplo.com
MAIL_PORT=587
MAIL_USER=user@exemplo.com
MAIL_PASS=senha
MAIL_FROM=noreply@exemplo.com
```

## Processo de Deploy

### 1. Configuração do Banco de Dados

O script de inicialização `start.sh` irá automaticamente:

1. Verificar a conexão com o PostgreSQL
2. Criar o banco de dados se não existir
3. Instalar as extensões necessárias (unaccent, uuid-ossp)
4. Executar as migrações para criar as tabelas
5. Criar um usuário administrador padrão se não existir

### 2. Deploy no Coolify

1. No dashboard do Coolify, crie um novo serviço
2. Selecione o repositório Git do TicketZap
3. Configure as variáveis de ambiente conforme listado acima
4. Defina o diretório do backend como `/backend`
5. Certifique-se de que o Dockerfile está configurado corretamente
6. Inicie o deploy

### 3. Verificação do Deploy

Após o deploy, verifique os logs para garantir que:

1. A conexão com o banco de dados foi estabelecida com sucesso
2. As migrações foram executadas corretamente
3. A aplicação iniciou sem erros

## Solução de Problemas

### Problema: Falha na conexão com o banco de dados

**Solução:**
- Verifique se a string de conexão `DATABASE_URL` está correta
- Confirme que o PostgreSQL está acessível a partir do container do Coolify
- Verifique as configurações de rede e firewall

### Problema: Falha nas migrações

**Solução:**
- Verifique os logs para identificar o erro específico
- Se necessário, conecte-se ao banco de dados manualmente e execute o script `create_tables.sql`
- Verifique se o usuário do PostgreSQL tem permissões suficientes

### Problema: Aplicação não inicia

**Solução:**
- Verifique se todas as variáveis de ambiente obrigatórias estão configuradas
- Examine os logs do container para identificar erros específicos
- Verifique se o Redis está acessível

## Alterações Recentes

### Correções de Problemas de Deploy

Recentemente, foram feitas alterações para resolver problemas de deploy com o Coolify. As seguintes melhorias foram implementadas:

- **Verificação de arquivos de script**: Agora, o sistema verifica se os arquivos `start.sh` e `create_tables.sql` estão presentes no diretório `backend/` antes de iniciar o deploy.
- **Permissões de arquivo**: O sistema agora configura automaticamente as permissões de execução para o arquivo `start.sh`.
- **Configuração de variáveis de ambiente**: Foram adicionadas verificações para garantir que todas as variáveis de ambiente necessárias estejam configuradas no Coolify.

## Manutenção

### Backup do Banco de Dados

Recomenda-se configurar backups regulares do banco de dados PostgreSQL. Isso pode ser feito através do Coolify ou diretamente no servidor PostgreSQL.

### Atualização da Aplicação

Para atualizar a aplicação:

1. Faça push das alterações para o repositório Git
2. No Coolify, acesse o serviço do TicketZap
3. Clique em "Redeploy" para iniciar o processo de atualização

## Suporte

Em caso de problemas ou dúvidas, entre em contato com a equipe de suporte técnico.
