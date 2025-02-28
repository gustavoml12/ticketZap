import { QueryInterface, DataTypes } from "sequelize";

module.exports = {
  up: (queryInterface: QueryInterface) => {
    return queryInterface.addColumn("Schedules", "ticketId", {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: { model: "Tickets", key: "id" },
      onUpdate: "CASCADE",
      onDelete: "SET NULL"
    });
  },

  down: (queryInterface: QueryInterface) => {
    return queryInterface.removeColumn("Schedules", "ticketId");
  }
};
