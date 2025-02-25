import { QueryInterface } from "sequelize";
import { hash } from "bcryptjs";

module.exports = {
    up: (queryInterface: QueryInterface) => {
        return queryInterface.sequelize.transaction(async t => {
            return Promise.all([
                queryInterface.bulkInsert(
                    "Settings",
                    [
                        {
                            key: "chatBotType",
                            value: "text",
                            companyId: 1,
                            createdAt: new Date(),
                            updatedAt: new Date()
                        },
                        {
                            key: "userRating",
                            value: "disabled",
                            companyId: 1,
                            createdAt: new Date(),
                            updatedAt: new Date()
                        },
                        {
                            key: "scheduleType",
                            value: "queue",
                            companyId: 1,
                            createdAt: new Date(),
                            updatedAt: new Date()
                        },
                        {
                            key: "CheckMsgIsGroup",
                            value: "enabled",
                            companyId: 1,
                            createdAt: new Date(),
                            updatedAt: new Date()
                        },
                        {
                            key:"call",
                            value: "disabled",
                            companyId: 1,
                            createdAt: new Date(),
                            updatedAt: new Date()
                        },
                        {
                            key: "ipixc",
                            value: "",
                            companyId: 1,
                            createdAt: new Date(),
                            updatedAt: new Date()
                        },
                        {
                            key: "tokenixc",
                            value: "",
                            companyId: 1,
                            createdAt: new Date(),
                            updatedAt: new Date()
                        },
                        {
                            key: "ipmkauth",
                            value: "",
                            companyId: 1,
                            createdAt: new Date(),
                            updatedAt: new Date()
                        },
                        {
                            key: "clientidmkauth",
                            value: "",
                            companyId: 1,
                            createdAt: new Date(),
                            updatedAt: new Date()
                        },
                        {
                            key: "clientsecretmkauth",
                            value: "",
                            companyId: 1,
                            createdAt: new Date(),
                            updatedAt: new Date()
                        },
                        {
                            key: "asaas",
                            value: "",
                            companyId: 1,
                            createdAt: new Date(),
                            updatedAt: new Date()
                        },
                        // Configurações públicas
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
        return queryInterface.bulkDelete("Settings", {});
    }
};
