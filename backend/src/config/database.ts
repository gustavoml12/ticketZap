import "../bootstrap";

module.exports = {
  define: {
    charset: "utf8",
    collate: "utf8_general_ci"
  },
  pool: {
    max: process.env.DB_MAX_CONNECTIONS || 60,
    min: process.env.DB_MIN_CONNECTIONS || 5,
    acquire: process.env.DB_ACQUIRE || 30000,
    idle: process.env.DB_IDLE || 10000
  },
  url: process.env.DATABASE_URL,
  dialect: "postgres",
  timezone: process.env.DB_TIMEZONE || "-03:00",
  host: process.env.DB_HOST,
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME,
  username: process.env.DB_USER,
  password: process.env.DB_PASS,
  logging: process.env.DB_DEBUG && console.log,
  seederStorage: "sequelize",
  dialectOptions: {
    ssl: false
  }
};
