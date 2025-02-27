# Instruções para Migrações do Banco de Dados

Este documento contém instruções para resolver problemas com as migrações do banco de dados no sistema TicketZap.

## Migrações Automáticas

O sistema está configurado para executar migrações automaticamente durante a inicialização do container, mas apenas se as tabelas ainda não existirem. Isso é feito através do script `start.sh` no Dockerfile, que:

1. Cria o diretório de configuração
2. Cria o arquivo `config.json` para o Sequelize
3. Verifica se o banco de dados está acessível
4. Verifica se a tabela `Settings` já existe
5. Se a tabela não existir, executa as migrações com `npx sequelize-cli db:migrate`
6. Inicia a aplicação com PM2

Isso garante que as migrações só sejam executadas quando necessário, evitando resetar o banco de dados a cada atualização.

## Solução Manual para Problemas de Migração

Se as migrações automáticas não funcionarem, você pode executar o script SQL manualmente no banco de dados. Siga estas etapas:

### Opção 1: Usando o Painel do Coolify

1. Acesse o painel do Coolify
2. Navegue até o serviço de banco de dados PostgreSQL
3. Procure a opção para executar comandos SQL
4. Cole o conteúdo do arquivo `create_tables.sql` e execute

### Opção 2: Usando o Terminal do Container

Se você tiver acesso ao terminal do container do banco de dados:

```bash
# Copie o arquivo create_tables.sql para o container
# Em seguida, execute:
cat create_tables.sql | psql -U postgres -d postgres
```

### Opção 3: Usando uma Ferramenta de Administração do PostgreSQL

Se você usa uma ferramenta como pgAdmin:

1. Conecte-se ao banco de dados usando as credenciais fornecidas pelo Coolify
2. Abra uma nova janela de consulta SQL
3. Cole o conteúdo do arquivo `create_tables.sql` e execute

## Verificando se as Migrações Foram Bem-sucedidas

Após executar as migrações, você pode verificar se as tabelas foram criadas corretamente:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';
```

Você deve ver uma lista de tabelas incluindo `Settings`, `Companies`, `Users`, etc.

## Criando um Usuário Administrador

Se necessário, você pode criar um usuário administrador manualmente:

```sql
INSERT INTO "Users" (
  "name", 
  "email", 
  "passwordHash", 
  "createdAt", 
  "updatedAt", 
  "profile", 
  "companyId", 
  "super"
) VALUES (
  'Admin', 
  'admin@exemplo.com', 
  '$2a$08$WaEmpmFDD/XkDqorkqY1ZOIGGAMkxS0ixY1vWky4nFCVORQvMgmwi', -- senha: 123456
  NOW(), 
  NOW(), 
  'admin', 
  1, 
  true
);
```

## Reiniciando o Serviço

Após executar as migrações, reinicie o serviço backend no Coolify para aplicar as alterações.

## Solução de Problemas Comuns

### Erro: relation "Settings" does not exist

Este erro ocorre quando a tabela `Settings` não foi criada. Verifique se:

1. As migrações foram executadas corretamente
2. O arquivo `config.json` foi criado no diretório correto
3. A string de conexão do banco de dados está correta

### Erro: Sequelize CLI não encontra o arquivo de configuração

Se o Sequelize CLI não conseguir encontrar o arquivo de configuração, verifique se:

1. O arquivo `config.json` está no diretório `/usr/src/app/config/`
2. O arquivo `.sequelizerc` está configurado corretamente
3. As permissões dos arquivos estão corretas

### Erro de Conexão com o Banco de Dados

Se houver problemas de conexão com o banco de dados, verifique:

1. A variável de ambiente `DATABASE_URL` está configurada corretamente
2. O banco de dados está acessível a partir do container do backend
3. As credenciais do banco de dados estão corretas
