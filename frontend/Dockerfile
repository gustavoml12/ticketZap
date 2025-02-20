FROM node:20-alpine as build-deps

WORKDIR /usr/src/app

# Copy package files first for better caching
COPY package*.json ./

# Install all dependencies including dev dependencies for build
RUN --mount=type=cache,target=/root/.npm \
    npm ci

# Copy the rest of the application
COPY . .

# Create config.json during build
RUN echo '{"BACKEND_PROTOCOL":"https","BACKEND_HOST":"ticket.ebnez.com.br","BACKEND_PATH":"/backend"}' > /usr/src/app/public/config.json

# Build the application
RUN npm run build

# Stage 2: Create the final image
FROM ghcr.io/ticketz-oss/nginx-alpine:latest

WORKDIR /usr/share/nginx/html

# Copy build files from build stage
COPY --from=build-deps /usr/src/app/build /var/www/public
COPY --from=build-deps /usr/src/app/node_modules/@socket.io/admin-ui/ui/dist /var/www/public/socket-admin

# Copy manifest and config files
RUN mkdir -p /var/www/public/settings && \
    echo '{"name":"TicketZap","short_name":"TicketZap","start_url":"/","display":"standalone","theme_color":"#000000","background_color":"#ffffff"}' > /var/www/public/manifest.json && \
    echo '{"value":"#2196f3"}' > /var/www/public/settings/primaryColorLight.json && \
    echo '{"value":""}' > /var/www/public/settings/appLogoLight.json && \
    echo '{"value":"light"}' > /var/www/public/settings/theme.json

# Copy nginx configuration
COPY nginx /etc/nginx

ENTRYPOINT ["dumb-init", "--"]
CMD (echo "{" && while IFS='=' read -r name value; do \
        printf '\t"%s": "%s"\n' "$name" "$value"; \
    done < <(env) | sed '$!s/$/,/' && echo "}")  > /var/www/public/config.json \
    && nginx -g "daemon off;"
