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
      "BACKEND_URL": "http://localhost:3000/api",  
      "LOG_LEVEL": "debug"
    };
  }
}

if (!config) {
  config = {
    "BACKEND_URL": "https://ticket.ebnez.com.br/api/",
    "LOG_LEVEL": "info"
  };
}

export function getBackendURL() {
  return config.BACKEND_URL;
}

export function getBackendSocketURL() {
  // Se a URL do backend é HTTPS, use WSS, caso contrário use WS
  const isSecure = config.BACKEND_URL.startsWith("https");
  const wsProtocol = isSecure ? "wss" : "ws";
  const baseUrl = config.BACKEND_URL.replace(/^https?:\/\//, '').replace(/\/api\/?$/, '');
  return `${wsProtocol}://${baseUrl}`;
}

export default config;
