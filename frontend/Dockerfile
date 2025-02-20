FROM node:20-alpine as build-deps

WORKDIR /usr/src/app

# Copy package files first for better caching
COPY package*.json ./

# Install all dependencies including dev dependencies for build
RUN --mount=type=cache,target=/root/.npm \
    npm ci

# Copy the rest of the application
COPY . .

# Build the application
RUN npm run build

# Stage 2: Create the final image
FROM ghcr.io/ticketz-oss/nginx-alpine:latest

WORKDIR /var/www/public

# Copy build files from build stage
COPY --from=build-deps /usr/src/app/build/ .
COPY --from=build-deps /usr/src/app/node_modules/@socket.io/admin-ui/ui/dist ./socket-admin

# Copy nginx configuration
COPY nginx /etc/nginx

# Create necessary directories and files
RUN mkdir -p settings && \
    echo '{"name":"TicketZap","short_name":"TicketZap","start_url":"/","display":"standalone","theme_color":"#000000","background_color":"#ffffff"}' > manifest.json && \
    echo '{"value":"#2196f3"}' > settings/primaryColorLight.json && \
    echo '{"value":""}' > settings/appLogoLight.json && \
    echo '{"value":"light"}' > settings/theme.json && \
    echo '{"BACKEND_PROTOCOL":"https","BACKEND_HOST":"ticket.ebnez.com.br","BACKEND_PATH":"/backend"}' > config.json

ENTRYPOINT ["dumb-init", "--"]
CMD ["nginx", "-g", "daemon off;"]
