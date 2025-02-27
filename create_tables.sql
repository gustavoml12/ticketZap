-- Criar extensão unaccent
CREATE EXTENSION IF NOT EXISTS unaccent;

-- Criar extensão uuid-ossp
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Criar tabela Companies
CREATE TABLE IF NOT EXISTS "Companies" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL UNIQUE,
  "phone" VARCHAR(255),
  "email" VARCHAR(255),
  "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "status" VARCHAR(255),
  "schedules" TEXT,
  "dueDate" TIMESTAMP WITH TIME ZONE,
  "recurrence" VARCHAR(255)
);

-- Inserir empresa padrão
INSERT INTO "Companies" ("id", "name", "createdAt", "updatedAt")
VALUES (1, 'Empresa Padrão', NOW(), NOW())
ON CONFLICT ("id") DO NOTHING;

-- Criar tabela Users
CREATE TABLE IF NOT EXISTS "Users" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "email" VARCHAR(255) NOT NULL,
  "passwordHash" VARCHAR(255) NOT NULL,
  "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "profile" VARCHAR(255),
  "tokenVersion" INTEGER,
  "companyId" INTEGER REFERENCES "Companies"("id") ON DELETE SET NULL ON UPDATE CASCADE,
  "super" BOOLEAN,
  "online" BOOLEAN
);

-- Criar tabela Settings
CREATE TABLE IF NOT EXISTS "Settings" (
  "id" SERIAL PRIMARY KEY,
  "key" VARCHAR(255) NOT NULL,
  "value" TEXT NOT NULL,
  "companyId" INTEGER REFERENCES "Companies"("id") ON DELETE SET NULL ON UPDATE CASCADE,
  "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Criar tabela UserSocketSessions
CREATE TABLE IF NOT EXISTS "UserSocketSessions" (
  "id" VARCHAR(255) PRIMARY KEY,
  "userId" INTEGER REFERENCES "Users"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  "active" BOOLEAN NOT NULL DEFAULT TRUE,
  "createdAt" TIMESTAMP(6) WITH TIME ZONE NOT NULL,
  "updatedAt" TIMESTAMP(6) WITH TIME ZONE NOT NULL
);

-- Criar tabela Whatsapps
CREATE TABLE IF NOT EXISTS "Whatsapps" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "session" TEXT,
  "qrcode" TEXT,
  "status" VARCHAR(255),
  "battery" VARCHAR(255),
  "plugged" BOOLEAN,
  "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "default" BOOLEAN,
  "companyId" INTEGER REFERENCES "Companies"("id") ON DELETE SET NULL ON UPDATE CASCADE,
  "greetingMessage" TEXT,
  "complationMessage" TEXT,
  "outOfHoursMessage" TEXT,
  "ratingMessage" TEXT,
  "farewellMessage" TEXT,
  "provider" VARCHAR(255),
  "facebookUserId" VARCHAR(255),
  "facebookPageUserId" VARCHAR(255),
  "tokenMeta" VARCHAR(255),
  "channel" VARCHAR(255) DEFAULT 'whatsapp',
  "transferMessage" TEXT
);

-- Criar tabela Contacts
CREATE TABLE IF NOT EXISTS "Contacts" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "number" VARCHAR(255) NOT NULL,
  "email" VARCHAR(255),
  "profilePicUrl" TEXT,
  "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "isGroup" BOOLEAN,
  "companyId" INTEGER REFERENCES "Companies"("id") ON DELETE SET NULL ON UPDATE CASCADE,
  "channel" VARCHAR(255),
  "disableBot" BOOLEAN,
  "presence" VARCHAR(255)
);

-- Criar tabela Queues
CREATE TABLE IF NOT EXISTS "Queues" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "color" VARCHAR(255) NOT NULL,
  "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "companyId" INTEGER REFERENCES "Companies"("id") ON DELETE SET NULL ON UPDATE CASCADE,
  "schedules" TEXT,
  "outOfHoursMessage" TEXT,
  "mediaPath" TEXT,
  "mediaName" TEXT
);

-- Criar tabela Tickets
CREATE TABLE IF NOT EXISTS "Tickets" (
  "id" SERIAL PRIMARY KEY,
  "status" VARCHAR(255) NOT NULL,
  "lastMessage" TEXT,
  "contactId" INTEGER REFERENCES "Contacts"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  "userId" INTEGER REFERENCES "Users"("id") ON DELETE SET NULL ON UPDATE CASCADE,
  "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "whatsappId" INTEGER REFERENCES "Whatsapps"("id") ON DELETE SET NULL ON UPDATE CASCADE,
  "isGroup" BOOLEAN,
  "unreadMessages" INTEGER,
  "queueId" INTEGER REFERENCES "Queues"("id") ON DELETE SET NULL ON UPDATE CASCADE,
  "companyId" INTEGER REFERENCES "Companies"("id") ON DELETE SET NULL ON UPDATE CASCADE,
  "uuid" UUID,
  "chatbot" BOOLEAN,
  "channel" VARCHAR(255)
);

-- Criar tabela Messages
CREATE TABLE IF NOT EXISTS "Messages" (
  "id" SERIAL PRIMARY KEY,
  "body" TEXT NOT NULL,
  "ack" INTEGER,
  "read" BOOLEAN,
  "mediaType" VARCHAR(255),
  "mediaUrl" TEXT,
  "ticketId" INTEGER REFERENCES "Tickets"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "userId" INTEGER REFERENCES "Users"("id") ON DELETE SET NULL ON UPDATE CASCADE,
  "isDeleted" BOOLEAN,
  "contactId" INTEGER REFERENCES "Contacts"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  "quotedMsgId" VARCHAR(255),
  "remoteJid" VARCHAR(255),
  "participant" VARCHAR(255),
  "dataJson" TEXT,
  "queueId" INTEGER REFERENCES "Queues"("id") ON DELETE SET NULL ON UPDATE CASCADE,
  "channel" VARCHAR(255),
  "isEdited" BOOLEAN,
  "thumbnailUrl" TEXT
);

-- Criar tabela QueueOptions
CREATE TABLE IF NOT EXISTS "QueueOptions" (
  "id" SERIAL PRIMARY KEY,
  "title" VARCHAR(255) NOT NULL,
  "message" TEXT,
  "option" VARCHAR(255) NOT NULL,
  "queueId" INTEGER REFERENCES "Queues"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "parentId" INTEGER REFERENCES "QueueOptions"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  "mediaPath" TEXT,
  "mediaName" TEXT,
  "optionType" VARCHAR(255),
  "forwardQueueId" INTEGER REFERENCES "Queues"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- Criar tabela Plans
CREATE TABLE IF NOT EXISTS "Plans" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "users" INTEGER NOT NULL DEFAULT 0,
  "connections" INTEGER NOT NULL DEFAULT 0,
  "queues" INTEGER NOT NULL DEFAULT 0,
  "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "value" DECIMAL(10,2),
  "public" BOOLEAN
);

-- Inserir plano padrão
INSERT INTO "Plans" ("id", "name", "users", "connections", "queues", "value", "public", "createdAt", "updatedAt")
VALUES (1, 'Plano Padrão', 10, 3, 3, 0, true, NOW(), NOW())
ON CONFLICT ("id") DO NOTHING;

-- Atualizar a coluna planId na tabela Companies
ALTER TABLE "Companies" ADD COLUMN IF NOT EXISTS "planId" INTEGER REFERENCES "Plans"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Atualizar o planId da empresa padrão
UPDATE "Companies" SET "planId" = 1 WHERE "id" = 1 AND "planId" IS NULL;
