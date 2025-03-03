'use strict';

module.exports = {
  up: async (queryInterface) => {
    try {
      await queryInterface.sequelize.query('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"');
    } catch (error) {
      console.error('Error creating uuid-ossp extension:', error);
      throw error;
    }
  },

  down: async () => {
    // Cannot drop extension as it might be used by other databases
    return Promise.resolve();
  }
};
