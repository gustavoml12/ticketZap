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
RUN mkdir -p public-settings/vector && \
    echo '{"name":"TicketZap","short_name":"TicketZap","start_url":"/","display":"standalone","theme_color":"#000000","background_color":"#ffffff","icons":[{"src":"/vector/favicon.ico","sizes":"64x64 32x32 24x24 16x16","type":"image/x-icon"}]}' > public-settings/manifest.json && \
    echo '{"value":"#2196f3"}' > public-settings/primaryColorLight.json && \
    echo '{"value":""}' > public-settings/appLogoLight.json && \
    echo '{"value":"light"}' > public-settings/theme.json && \
    echo '{"BACKEND_PROTOCOL":"https","BACKEND_HOST":"ticket.ebnez.com.br","BACKEND_PATH":"/backend"}' > public-settings/config.json && \
    cp /etc/nginx/favicon.ico public-settings/vector/favicon.ico

ENTRYPOINT ["dumb-init", "--"]
CMD ["nginx", "-g", "daemon off;"]
