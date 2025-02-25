import { QueryInterface } from "sequelize";

module.exports = {
    up: (queryInterface: QueryInterface) => {
        return queryInterface.sequelize.transaction(async t => {
            return Promise.all([
                queryInterface.bulkInsert(
                    "Settings",
                    [
                        {
                            key: "primaryColorLight",
                            value: "#2563eb",
                            companyId: 1,
                            createdAt: new Date(),
                            updatedAt: new Date()
                        },
                        {
                            key: "primaryColorDark",
                            value: "#3b82f6",
                            companyId: 1,
                            createdAt: new Date(),
                            updatedAt: new Date()
                        },
                        {
                            key: "appLogoLight",
                            value: "logo-light.png",
                            companyId: 1,
                            createdAt: new Date(),
                            updatedAt: new Date()
                        },
                        {
                            key: "appLogoDark",
                            value: "logo-dark.png",
                            companyId: 1,
                            createdAt: new Date(),
                            updatedAt: new Date()
                        },
                        {
                            key: "appLogoFavicon",
                            value: "favicon.ico",
                            companyId: 1,
                            createdAt: new Date(),
                            updatedAt: new Date()
                        },
                        {
                            key: "appName",
                            value: "TicketZap",
                            companyId: 1,
                            createdAt: new Date(),
                            updatedAt: new Date()
                        }
                    ],
                    { transaction: t }
                )
            ]);
        });
    },

    down: async (queryInterface: QueryInterface) => {
        return queryInterface.bulkDelete("Settings", {
            key: [
                "primaryColorLight",
                "primaryColorDark",
                "appLogoLight",
                "appLogoDark",
                "appLogoFavicon",
                "appName"
            ]
        });
    }
};
