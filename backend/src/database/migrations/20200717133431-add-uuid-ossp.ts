import { QueryInterface } from 'sequelize';

module.exports = {
  up: async (queryInterface: QueryInterface) => {
    try {
      await queryInterface.sequelize.query('CREATE EXTENSION IF NOT EXISTS "uuid-ossp";');
      return Promise.resolve();
    } catch (error) {
      return Promise.reject(error);
    }
  },

  down: async (queryInterface: QueryInterface) => {
    try {
      await queryInterface.sequelize.query('DROP EXTENSION IF EXISTS "uuid-ossp";');
      return Promise.resolve();
    } catch (error) {
      return Promise.reject(error);
    }
  }
};
