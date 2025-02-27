# Guia de Solução de Problemas para Docker Build

Este guia fornece instruções detalhadas para solucionar problemas comuns durante o processo de build e deploy usando Docker, especialmente no ambiente Coolify.

## Problemas Comuns e Soluções

### 1. Build Lento ou Travado

#### Sintomas:
- O processo de build parece estar preso em uma etapa específica
- Nenhum progresso é mostrado nos logs por um longo período
- O build falha com timeout

#### Soluções:

##### Monitorar o Processo de Build
Use o script `monitor_build.sh` para obter informações detalhadas sobre o container durante o build:

```bash
./monitor_build.sh <container_id_ou_nome>
```

##### Otimizar o Dockerfile
- **Reduzir o contexto de build**: Use um `.dockerignore` adequado para excluir arquivos desnecessários
- **Combinar comandos RUN**: Use `&&` para combinar comandos relacionados e reduzir o número de camadas
- **Usar cache de build**: Utilize a funcionalidade de cache do Docker para acelerar builds subsequentes
- **Otimizar a ordem das instruções**: Coloque as instruções que mudam com menos frequência no início do Dockerfile

##### Ajustar Recursos
- Aumente os recursos disponíveis para o Docker (CPU, memória)
- Verifique se há espaço em disco suficiente para o build

##### Depurar Etapas Específicas
Se o build trava em uma etapa específica:

```bash
# Construir até a etapa problemática
docker build --target <nome_do_estágio> -t debug-image .

# Iniciar um shell interativo na imagem parcialmente construída
docker run -it debug-image /bin/sh

# Executar manualmente os comandos da etapa problemática para identificar o problema
```

### 2. Arquivos Ausentes Durante o Build

#### Sintomas:
- Erros como "file not found" ou "no such file or directory"
- Build falha ao tentar copiar ou acessar arquivos

#### Soluções:

##### Verificar a Estrutura de Arquivos
- Confirme que os arquivos necessários estão presentes no contexto de build
- Verifique se os caminhos no Dockerfile estão corretos

```bash
# Listar arquivos no diretório atual (onde o build é executado)
ls -la

# Verificar se arquivos específicos existem
find . -name "start.sh"
find . -name "create_tables.sql"
```

##### Copiar Arquivos Ausentes
Se os arquivos necessários estiverem em outro diretório, copie-os para o diretório de build:

```bash
cp /caminho/para/arquivo /caminho/para/diretório/de/build/
```

##### Ajustar o Dockerfile
Modifique o Dockerfile para usar os caminhos corretos:

```dockerfile
# Exemplo: copiar arquivos de um diretório pai
COPY ../arquivo.txt /destino/no/container/
```

### 3. Problemas de Permissão

#### Sintomas:
- Erros como "permission denied"
- Falhas ao tentar executar scripts ou acessar arquivos

#### Soluções:

##### Verificar e Ajustar Permissões
```bash
# Verificar permissões atuais
ls -la /caminho/para/arquivo

# Ajustar permissões
chmod +x /caminho/para/script.sh
```

##### Usar Usuário Não-Root no Dockerfile
```dockerfile
# Criar usuário não-root
RUN addgroup -g 1001 -S appuser && \
    adduser -u 1001 -S appuser -G appuser

# Definir permissões
RUN chown -R appuser:appuser /diretório/da/aplicação

# Mudar para o usuário não-root
USER appuser
```

## Comandos Úteis para Diagnóstico

### Verificar Logs do Container
```bash
docker logs <container_id_ou_nome>
```

### Inspecionar o Container
```bash
docker inspect <container_id_ou_nome>
```

### Verificar Uso de Recursos
```bash
docker stats <container_id_ou_nome>
```

### Executar Comandos em um Container em Execução
```bash
docker exec -it <container_id_ou_nome> /bin/sh
```

## Melhores Práticas para Builds Docker

1. **Mantenha o contexto de build pequeno**: Use `.dockerignore` para excluir arquivos desnecessários
2. **Minimize o número de camadas**: Combine comandos RUN relacionados
3. **Otimize a ordem das instruções**: Coloque as instruções que mudam com menos frequência no início
4. **Use multi-stage builds**: Separe o ambiente de build do ambiente de execução
5. **Utilize cache de build**: Estruture o Dockerfile para maximizar o uso de cache
6. **Prefira imagens oficiais e leves**: Use imagens Alpine quando possível
7. **Documente requisitos e dependências**: Mantenha a documentação atualizada

## Recursos Adicionais

- [Documentação oficial do Docker](https://docs.docker.com/)
- [Melhores práticas para escrever Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Otimização de imagens Docker](https://docs.docker.com/develop/develop-images/image_optimization/)
