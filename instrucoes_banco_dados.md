# Instruções para Criar as Tabelas do Banco de Dados

Este documento contém instruções para criar manualmente as tabelas necessárias no banco de dados PostgreSQL para o sistema TicketZap.

## Opção 1: Executar o Script SQL Diretamente

1. Acesse o terminal do servidor PostgreSQL ou use uma ferramenta como pgAdmin.

2. Conecte-se ao banco de dados usando a string de conexão:
   ```
   postgres://postgres:sBRFcX3M3z6SY0W5V6Jz42yzBOlM4qiBDXx9pkcoRb1qOTvuF0KdxF8M3YuGwpsJ@u80ggksoo4k40ccwsg8ww4k0:5432/postgres
   ```

3. Execute o script SQL `create_tables.sql` que foi criado.

## Opção 2: Executar o Script a partir do Container

Se você tiver acesso ao terminal do container do backend, pode executar o seguinte comando:

```bash
# Copie o arquivo create_tables.sql para o container (se estiver usando o Coolify, faça upload pelo painel)
# Em seguida, execute:
cat create_tables.sql | PGPASSWORD=sBRFcX3M3z6SY0W5V6Jz42yzBOlM4qiBDXx9pkcoRb1qOTvuF0KdxF8M3YuGwpsJ psql -h u80ggksoo4k40ccwsg8ww4k0 -U postgres -d postgres
```

## Opção 3: Executar o Script a partir do Coolify

1. No painel do Coolify, vá até o serviço de banco de dados PostgreSQL.
2. Procure a opção para executar comandos SQL ou acessar o terminal.
3. Cole o conteúdo do arquivo `create_tables.sql` e execute.

## Após Criar as Tabelas

Depois de criar as tabelas, reinicie o serviço backend:

```bash
pm2 restart all
```

Verifique os logs para confirmar que o serviço está funcionando corretamente:

```bash
pm2 logs
```

## Observações Importantes

1. Este script cria as tabelas básicas necessárias para o funcionamento do sistema.
2. Uma empresa padrão (ID 1) e um plano padrão (ID 1) são criados automaticamente.
3. Você precisará criar manualmente um usuário administrador após a criação das tabelas.

## Criando um Usuário Administrador

Após criar as tabelas, você pode criar um usuário administrador executando o seguinte comando SQL:

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

Este comando cria um usuário administrador com as seguintes credenciais:
- Email: admin@exemplo.com
- Senha: 123456
