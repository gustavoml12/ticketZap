-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Tabela Users
CREATE TABLE IF NOT EXISTS "Users" (
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(255) NOT NULL,
    "email" VARCHAR(255) UNIQUE NOT NULL,
    "passwordHash" VARCHAR(255) NOT NULL,
    "profile" VARCHAR(255) DEFAULT 'admin',
    "tokenVersion" INTEGER DEFAULT 0,
    "super" BOOLEAN DEFAULT false,
    "companyId" INTEGER,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Tabela Companies
CREATE TABLE IF NOT EXISTS "Companies" (
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(255) NOT NULL,
    "status" BOOLEAN DEFAULT true,
    "planId" INTEGER,
    "schedules" JSON,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Tabela Contacts
CREATE TABLE IF NOT EXISTS "Contacts" (
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(255),
    "number" VARCHAR(255) NOT NULL,
    "email" VARCHAR(255),
    "isGroup" BOOLEAN DEFAULT false,
    "companyId" INTEGER,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    FOREIGN KEY ("companyId") REFERENCES "Companies"("id") ON DELETE CASCADE
);

-- Tabela Tickets
CREATE TABLE IF NOT EXISTS "Tickets" (
    "id" SERIAL PRIMARY KEY,
    "status" VARCHAR(255) NOT NULL,
    "unreadMessages" INTEGER DEFAULT 0,
    "lastMessage" TEXT,
    "contactId" INTEGER,
    "companyId" INTEGER,
    "queueId" INTEGER,
    "whatsappId" INTEGER,
    "userId" INTEGER,
    "isGroup" BOOLEAN DEFAULT false,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    FOREIGN KEY ("contactId") REFERENCES "Contacts"("id") ON DELETE CASCADE,
    FOREIGN KEY ("companyId") REFERENCES "Companies"("id") ON DELETE CASCADE
);

-- Tabela Messages
CREATE TABLE IF NOT EXISTS "Messages" (
    "id" SERIAL PRIMARY KEY,
    "body" TEXT NOT NULL,
    "ticketId" INTEGER NOT NULL,
    "contactId" INTEGER,
    "companyId" INTEGER,
    "fromMe" BOOLEAN NOT NULL DEFAULT false,
    "isDeleted" BOOLEAN NOT NULL DEFAULT false,
    "quotedMsgId" VARCHAR(255),
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    FOREIGN KEY ("ticketId") REFERENCES "Tickets"("id") ON DELETE CASCADE,
    FOREIGN KEY ("contactId") REFERENCES "Contacts"("id") ON DELETE CASCADE,
    FOREIGN KEY ("companyId") REFERENCES "Companies"("id") ON DELETE CASCADE
);

-- Tabela Whatsapps (atualizada com novos campos)
CREATE TABLE IF NOT EXISTS "Whatsapps" (
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(255) NOT NULL,
    "number" VARCHAR(255) NOT NULL,
    "queueId" INTEGER,
    "companyId" INTEGER,
    "greetingMessage" TEXT,
    "farewellMessage" TEXT,
    "complationMessage" TEXT,
    "outOfHoursMessage" TEXT,
    "ratingMessage" TEXT,
    "transferMessage" TEXT,
    "status" VARCHAR(255),
    "isDefault" BOOLEAN NOT NULL DEFAULT false,
    "retries" INTEGER DEFAULT 0,
    "session" TEXT,
    "qrcode" TEXT,
    "battery" TEXT,
    "plugged" BOOLEAN,
    "provider" VARCHAR(255),
    "token" TEXT,
    "facebookUserId" VARCHAR(255),
    "facebookUserToken" TEXT,
    "facebookPageUserId" VARCHAR(255),
    "tokenMeta" TEXT,
    "channel" VARCHAR(255),
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    FOREIGN KEY ("companyId") REFERENCES "Companies"("id") ON DELETE CASCADE
);

-- Tabela Queues
CREATE TABLE IF NOT EXISTS "Queues" (
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(255) NOT NULL,
    "companyId" INTEGER,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    FOREIGN KEY ("companyId") REFERENCES "Companies"("id") ON DELETE CASCADE
);

-- Adicionar coluna greetingMessage à tabela Queues
ALTER TABLE "Queues" ADD COLUMN IF NOT EXISTS "greetingMessage" TEXT DEFAULT '';

-- Tabela Settings
CREATE TABLE IF NOT EXISTS "Settings" (
    "id" SERIAL PRIMARY KEY,
    "key" VARCHAR(255) NOT NULL,
    "value" TEXT,
    "companyId" INTEGER,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    FOREIGN KEY ("companyId") REFERENCES "Companies"("id") ON DELETE CASCADE
);

-- Tabela ContactCustomFields
CREATE TABLE IF NOT EXISTS "ContactCustomFields" (
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(255) NOT NULL,
    "value" TEXT,
    "contactId" INTEGER NOT NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    FOREIGN KEY ("contactId") REFERENCES "Contacts"("id") ON DELETE CASCADE
);

-- Tabela Plans
CREATE TABLE IF NOT EXISTS "Plans" (
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(255) NOT NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Tabela TicketNotes
CREATE TABLE IF NOT EXISTS "TicketNotes" (
    "id" SERIAL PRIMARY KEY,
    "note" TEXT NOT NULL,
    "ticketId" INTEGER NOT NULL,
    "companyId" INTEGER,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    FOREIGN KEY ("ticketId") REFERENCES "Tickets"("id") ON DELETE CASCADE,
    FOREIGN KEY ("companyId") REFERENCES "Companies"("id") ON DELETE CASCADE
);

-- Tabela QuickMessages
CREATE TABLE IF NOT EXISTS "QuickMessages" (
    "id" SERIAL PRIMARY KEY,
    "message" TEXT NOT NULL,
    "companyId" INTEGER,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    FOREIGN KEY ("companyId") REFERENCES "Companies"("id") ON DELETE CASCADE
);

-- Tabela Helps
CREATE TABLE IF NOT EXISTS "Helps" (
    "id" SERIAL PRIMARY KEY,
    "title" VARCHAR(255) NOT NULL,
    "description" TEXT NOT NULL,
    "video" VARCHAR(255),
    "link" VARCHAR(255),
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Tabela UserQueues (Relacionamento N:N entre Users e Queues)
CREATE TABLE IF NOT EXISTS "UserQueues" (
    "userId" INTEGER NOT NULL,
    "queueId" INTEGER NOT NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY ("userId", "queueId"),
    FOREIGN KEY ("userId") REFERENCES "Users"("id") ON DELETE CASCADE,
    FOREIGN KEY ("queueId") REFERENCES "Queues"("id") ON DELETE CASCADE
);

-- Tabela Schedules
CREATE TABLE IF NOT EXISTS "Schedules" (
    "id" SERIAL PRIMARY KEY,
    "ticketId" INTEGER,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    FOREIGN KEY ("ticketId") REFERENCES "Tickets"("id") ON DELETE SET NULL
);

-- Tabela Campaigns
CREATE TABLE IF NOT EXISTS "Campaigns" (
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(255) NOT NULL,
    "status" VARCHAR(255) NOT NULL DEFAULT 'PROGRAMADA',
    "scheduledAt" TIMESTAMP WITH TIME ZONE,
    "companyId" INTEGER,
    "userId" INTEGER,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    FOREIGN KEY ("companyId") REFERENCES "Companies"("id") ON DELETE CASCADE,
    FOREIGN KEY ("userId") REFERENCES "Users"("id") ON DELETE CASCADE
);

-- Tabela WhatsappQueues (relacionamento N:N entre Whatsapps e Queues)
CREATE TABLE IF NOT EXISTS "WhatsappQueues" (
    "whatsappId" INTEGER NOT NULL,
    "queueId" INTEGER NOT NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY ("whatsappId", "queueId"),
    FOREIGN KEY ("whatsappId") REFERENCES "Whatsapps"("id") ON DELETE CASCADE,
    FOREIGN KEY ("queueId") REFERENCES "Queues"("id") ON DELETE CASCADE
);

-- Adicionando índices para WhatsappQueues
CREATE INDEX IF NOT EXISTS "idx_whatsappqueues_whatsappId" ON "WhatsappQueues"("whatsappId");
CREATE INDEX IF NOT EXISTS "idx_whatsappqueues_queueId" ON "WhatsappQueues"("queueId");

CREATE INDEX IF NOT EXISTS "idx_campaigns_status" ON "Campaigns"("status");
CREATE INDEX IF NOT EXISTS "idx_campaigns_scheduledAt" ON "Campaigns"("scheduledAt");

-- Índices para melhor performance
CREATE INDEX IF NOT EXISTS "idx_tickets_status" ON "Tickets"("status");
CREATE INDEX IF NOT EXISTS "idx_tickets_contactId" ON "Tickets"("contactId");
CREATE INDEX IF NOT EXISTS "idx_tickets_companyId" ON "Tickets"("companyId");
CREATE INDEX IF NOT EXISTS "idx_messages_ticketId" ON "Messages"("ticketId");
CREATE INDEX IF NOT EXISTS "idx_contacts_number" ON "Contacts"("number");
CREATE INDEX IF NOT EXISTS "idx_users_email" ON "Users"("email");

-- Inserir usuário admin padrão
INSERT INTO "Companies" ("name", "status", "createdAt", "updatedAt")
VALUES ('Empresa Padrão', true, NOW(), NOW())
ON CONFLICT DO NOTHING;

INSERT INTO "Users" ("name", "email", "passwordHash", "profile", "super", "companyId", "createdAt", "updatedAt")
VALUES (
    'Admin',
    'admin@admin.com',
    '$2a$08$WG6GhHPpAWk6HrKD0PQqkuDZwLahH1X4HQh5TGNhO6F4TvQSJcG4.',
    'admin',
    true,
    1,
    NOW(),
    NOW()
) ON CONFLICT DO NOTHING;
