'use strict';

const { QueryInterface, DataTypes } = require("sequelize");

module.exports = {
  up: async (queryInterface: QueryInterface) => {
    try {
      await queryInterface.createTable("Users", {
        id: {
          type: DataTypes.INTEGER,
          autoIncrement: true,
          primaryKey: true,
          allowNull: false
        },
        name: {
          type: DataTypes.STRING,
          allowNull: false
        },
        email: {
          type: DataTypes.STRING,
          allowNull: false,
          unique: true
        },
        passwordHash: {
          type: DataTypes.STRING,
          allowNull: false
        },
        createdAt: {
          type: DataTypes.DATE,
          allowNull: false
        },
        updatedAt: {
          type: DataTypes.DATE,
          allowNull: false
        }
      });
    } catch (error) {
      console.error('Error creating Users table:', error);
      throw error;
    }
  },

  down: async (queryInterface: QueryInterface) => {
    try {
      await queryInterface.dropTable("Users");
    } catch (error) {
      console.error('Error dropping Users table:', error);
      throw error;
    }
  }
};
