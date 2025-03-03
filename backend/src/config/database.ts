require("../bootstrap");

module.exports = {
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
  url: process.env.DATABASE_URL,
  dialect: "postgres",
  timezone: "-03:00",
  logging: false,
  seederStorage: "sequelize",
  dialectOptions: {
    ssl: false
  }
};
