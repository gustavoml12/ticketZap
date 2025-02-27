const fs = require('fs');
const path = require('path');

// Função para exibir logs com timestamp
function log(message) {
  const timestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);
  console.log(`[${timestamp}] ${message}`);
}

// Verificar variável de ambiente DATABASE_URL
if (!process.env.DATABASE_URL) {
  log('ERRO: Variável de ambiente DATABASE_URL não está definida');
  process.exit(1);
}

log('Iniciando preparação da configuração para migrações...');

// Create config directory if it doesn't exist
const configDir = path.join(__dirname, 'config');
if (!fs.existsSync(configDir)) {
  log(`Criando diretório de configuração: ${configDir}`);
  fs.mkdirSync(configDir, { recursive: true });
}

// Create config.json file for Sequelize CLI
log('Gerando arquivo config.json para Sequelize CLI');
const configJson = {
  development: {
    url: process.env.DATABASE_URL,
    dialect: "postgres",
    timezone: "-03:00",
    logging: false,
    define: {
      charset: "utf8",
      collate: "utf8_general_ci"
    },
    pool: {
      max: 60,
      min: 5,
      acquire: 30000,
      idle: 10000
    },
    dialectOptions: {
      ssl: false
    }
  },
  test: {
    url: process.env.DATABASE_URL,
    dialect: "postgres",
    timezone: "-03:00",
    logging: false,
    define: {
      charset: "utf8",
      collate: "utf8_general_ci"
    },
    pool: {
      max: 60,
      min: 5,
      acquire: 30000,
      idle: 10000
    },
    dialectOptions: {
      ssl: false
    }
  },
  production: {
    url: process.env.DATABASE_URL,
    dialect: "postgres",
    timezone: "-03:00",
    logging: false,
    define: {
      charset: "utf8",
      collate: "utf8_general_ci"
    },
    pool: {
      max: 60,
      min: 5,
      acquire: 30000,
      idle: 10000
    },
    dialectOptions: {
      ssl: false
    }
  }
};

const configFilePath = path.join(configDir, 'config.json');
try {
  fs.writeFileSync(configFilePath, JSON.stringify(configJson, null, 2));
  log(`Arquivo de configuração criado com sucesso: ${configFilePath}`);
  
  // Verificar se o arquivo foi realmente criado
  if (fs.existsSync(configFilePath)) {
    const stats = fs.statSync(configFilePath);
    log(`Tamanho do arquivo: ${stats.size} bytes`);
    log('Conteúdo do arquivo de configuração:');
    console.log('-----------------------------------');
    console.log(JSON.stringify(configJson, null, 2));
    console.log('-----------------------------------');
  }
  
  log('Preparação da configuração concluída com sucesso');
} catch (error) {
  log(`ERRO ao criar arquivo de configuração: ${error.message}`);
  process.exit(1);
}
