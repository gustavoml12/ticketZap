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
import { version } from "./controllers/VersionController";

Sentry.init({ dsn: process.env.SENTRY_DSN });

const app = express();

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

// Configurar para retornar JSON em vez de HTML para erros
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  if (err instanceof AppError) {
    logger.error(err);
    return res.status(err.statusCode).json({ error: err.message });
  }

  logger.error(err);
  return res.status(500).json({ error: "Internal server error" });
});

// Rota raiz - retorna informações básicas
app.get("/", version);

// Health check endpoint
app.get("/health", (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Servir arquivos estáticos
app.use("/uploads", express.static(uploadConfig.uploadsDirectory));
app.use("/public", express.static(uploadConfig.publicDirectory));
app.use(express.static(path.resolve(__dirname, "..", "public")));

// Servir manifest.json
app.get("/manifest.json", (req, res) => {
  res.sendFile(path.resolve(__dirname, "..", "public", "manifest.json"));
});

// Usar as rotas
app.use(routes);

// Capturar erros do Sentry
app.use(Sentry.Handlers.errorHandler());

// Express vai enviar todos os erros como JSON
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  if (res.headersSent) {
    return next(err);
  }
  
  logger.error(err);
  return res.status(500).json({ 
    error: "Internal server error",
    message: err.message
  });
});

export default app;
