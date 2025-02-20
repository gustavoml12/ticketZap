import gracefulShutdown from "http-graceful-shutdown";
import app from "./app";
import { initIO } from "./libs/socket";
import { logger } from "./utils/logger";
import { StartAllWhatsAppsSessions } from "./services/WbotServices/StartAllWhatsAppsSessions";
import Company from "./models/Company";
import { startQueueProcess } from "./queues";
import {
  checkOpenInvoices,
  payGatewayInitialize
} from "./services/PaymentGatewayServices/PaymentGatewayServices";

// Environment Variable Validation
if (!process.env.PORT) {
  logger.error("PORT environment variable is not set.");
  process.exit(1);
}

// Function to start server and initialize services
async function startServer() {
  try {
    // Health check endpoint - respond early to prevent container from being killed
    app.get("/", (req, res) => {
      res.send("OK");
    });

    // Create and start the server first
    const server = app.listen(process.env.PORT, () => {
      logger.info(`Server is listening on port: ${process.env.PORT}`);
    });

    // Initialize socket.io
    initIO(server);
    logger.info("Socket.IO initialized");

    // Start processing queues
    startQueueProcess();
    logger.info("Queue processing started");

    // Initialize payment gateway
    await payGatewayInitialize();
    logger.info("Payment gateway initialized");

    // Start WhatsApp sessions for all companies
    const companies = await Company.findAll();
    await Promise.all(
      companies.map(async company => {
        try {
          await StartAllWhatsAppsSessions(company.id);
          logger.info(`Started WhatsApp session for company ID: ${company.id}`);
        } catch (error) {
          logger.error(
            `Error starting WhatsApp session for company ID: ${company.id} - ${error.message}`
          );
        }
      })
    );

    // Setup graceful shutdown
    gracefulShutdown(server, {
      signals: "SIGINT SIGTERM",
      timeout: 30000,
      onShutdown: async () => {
        logger.info("Shutdown initiated. Cleaning up...");
      },
      finally: () => {
        logger.info("Server has shut down.");
      }
    });

    // Start checking open invoices
    checkOpenInvoices();
    
    return server;
  } catch (err) {
    logger.error(err);
    process.exit(1);
  }
}

// Global Exception Handlers
process.on("uncaughtException", err => {
  logger.error({ err }, `Uncaught Exception: ${err.message}`);
  process.exit(1);
});

// Global Exception Handlers for logging only
// eslint-disable-next-line @typescript-eslint/no-explicit-any
process.on("unhandledRejection", (reason: any, promise) => {
  logger.debug({ promise, reason }, "Unhandled Rejection");
});

startServer();
