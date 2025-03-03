import { QueryInterface, DataTypes } from 'sequelize';

module.exports = {
  up: async (queryInterface: typeof QueryInterface) => {
    try {
      await queryInterface.createTable('Users', {
        id: {
          type: DataTypes.UUID,
          defaultValue: DataTypes.UUIDV4,
          allowNull: false,
          primaryKey: true,
        },
        name: {
          type: DataTypes.STRING,
          allowNull: false,
        },
        email: {
          type: DataTypes.STRING,
          allowNull: false,
          unique: true,
        },
        passwordHash: {
          type: DataTypes.STRING,
          allowNull: false,
        },
        createdAt: {
          type: DataTypes.DATE,
          allowNull: false,
        },
        updatedAt: {
          type: DataTypes.DATE,
          allowNull: false,
        },
      });
      return Promise.resolve();
    } catch (error) {
      return Promise.reject(error);
    }
  },

  down: async (queryInterface: typeof QueryInterface) => {
    try {
      await queryInterface.dropTable('Users');
      return Promise.resolve();
    } catch (error) {
      return Promise.reject(error);
    }
  }
};
