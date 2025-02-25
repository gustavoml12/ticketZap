import { loadJSON } from "../helpers/loadJSON";

// If config.json is not found and the hostname is localhost or 127.0.0 load config-dev.json
let config = loadJSON("/config.json");

if (!config && ["localhost", "127.0.0.1"].includes(window.location.hostname)) {
  config = loadJSON("/config-dev.json");
  if (!config) {
    config = {
      "BACKEND_PROTOCOL": "http",
      "BACKEND_HOST": window.location.hostname,
      "BACKEND_PORT": window.location.port,
      "BACKEND_URL": "/backend",  
      "LOG_LEVEL": "debug"
    };
  }
}

if (!config) {
  throw new Error("Config not found");
}

export function getBackendURL() {
  if (config.BACKEND_URL) {
    return config.BACKEND_URL;
  }
  
  const protocol = config.BACKEND_PROTOCOL || window.location.protocol.replace(":", "");
  const host = config.BACKEND_HOST || window.location.hostname;
  const port = config.BACKEND_PORT ? `:${config.BACKEND_PORT}` : "";
  
  return `${protocol}://${host}${port}/backend`;
}

export function getBackendSocketURL() {
  const protocol = config.BACKEND_PROTOCOL === "https" ? "wss" : "ws";
  const host = config.BACKEND_HOST || window.location.hostname;
  const port = config.BACKEND_PORT ? `:${config.BACKEND_PORT}` : "";
  
  return `${protocol}://${host}${port}/backend`;
}

export default config;
