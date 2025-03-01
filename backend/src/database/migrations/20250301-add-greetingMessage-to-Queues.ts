import { QueryInterface, DataTypes } from "sequelize";

module.exports = {
  up: (queryInterface: QueryInterface) => {
    return queryInterface.addColumn("Queues", "greetingMessage", {
      type: DataTypes.TEXT,
      allowNull: true,
      defaultValue: ""
    });
  },

  down: (queryInterface: QueryInterface) => {
    return queryInterface.removeColumn("Queues", "greetingMessage");
  }
};
