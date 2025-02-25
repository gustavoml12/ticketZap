import "./bootstrap";
import "reflect-metadata";
import "express-async-errors";
import express, { Request, Response, NextFunction } from "express";
import cors from "cors";
import cookieParser from "cookie-parser";
import * as Sentry from "@sentry/node";
import path from "path";

import "./database";
import uploadConfig from "./config/upload";
import AppError from "./errors/AppError";
import routes from "./routes";
import { logger } from "./utils/logger";
import { messageQueue, sendScheduledMessages } from "./queues";

Sentry.init({ dsn: process.env.SENTRY_DSN });

const app = express();
const baseUrl = process.env.BASE_URL || '/backend';

app.set("queues", {
  messageQueue,
  sendScheduledMessages
});

app.use(
  cors({
    credentials: true,
    origin: process.env.FRONTEND_URL
  })
);

app.use(cookieParser());
app.use(express.json());
app.use(Sentry.Handlers.requestHandler());

// Health check endpoint
app.get(`${baseUrl}/health`, (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Servir arquivos estáticos
app.use(`${baseUrl}/uploads`, express.static(uploadConfig.uploadsDirectory));
app.use(`${baseUrl}/public`, express.static(uploadConfig.publicDirectory));
app.use(baseUrl, express.static(path.resolve(__dirname, "..", "public")));

// Servir manifest.json
app.get(`${baseUrl}/manifest.json`, (req, res) => {
  res.sendFile(path.resolve(__dirname, "..", "public", "manifest.json"));
});

// Servir configurações públicas
app.get(`${baseUrl}/public-settings/:setting`, (req, res) => {
  const { setting } = req.params;
  
  // Log para debug
  console.log(`[DEBUG] Recebida requisição para configuração: ${setting}`);
  
  // Configurações padrão
  const defaultSettings = {
    allowSignup: false,
    primaryColorLight: "#007AFF",
    primaryColorDark: "#0A84FF",
    appName: "TicketZap",
    appLogoDark: "/backend/public/logo-dark.png",
    appLogoLight: "/backend/public/logo-light.png",
    appLogoFavicon: "/backend/public/favicon.ico",
    primaryColor: "#007AFF",
    primaryColorDark: "#0A84FF",
    primaryColorLight: "#007AFF"
  };

  // Log para debug
  console.log(`[DEBUG] Configuração solicitada: ${setting}`);
  console.log(`[DEBUG] Valor da configuração: ${defaultSettings[setting]}`);

  if (setting in defaultSettings) {
    res.json(defaultSettings[setting]);
  } else {
    console.log(`[DEBUG] Configuração não encontrada: ${setting}`);
    res.status(404).json({ error: "Setting not found" });
  }
});

// Adicionar o prefixo base às rotas da API
app.use(baseUrl, routes);

app.use(Sentry.Handlers.errorHandler());
app.use(async (err: Error, req: Request, res: Response, _: NextFunction) => {
  if (err instanceof AppError) {
    logger[err.level](err);
    return res.status(err.statusCode).json({ error: err.message });
  }

  logger.error(err);
  return res.status(500).json({ error: "Internal server error" });
});

export default app;
