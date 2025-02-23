# Build stage
FROM node:20-alpine as build-deps

# Set working directory
WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install dependencies using cache mount
RUN --mount=type=cache,target=/root/.npm \
    npm install

# Copy source code
COPY . .

# Set build arguments
ARG REACT_APP_BACKEND_URL
ARG NODE_ENV=production
ARG DISABLE_ESLINT_PLUGIN=true
ARG GENERATE_SOURCEMAP=false
ARG CI=false
ARG NODE_OPTIONS=--max-old-space-size=2048

# Set environment variables
ENV REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL
ENV NODE_ENV=$NODE_ENV
ENV DISABLE_ESLINT_PLUGIN=$DISABLE_ESLINT_PLUGIN
ENV GENERATE_SOURCEMAP=$GENERATE_SOURCEMAP
ENV CI=$CI
ENV NODE_OPTIONS=$NODE_OPTIONS

# Create config.json
RUN echo '{"REACT_APP_BACKEND_URL":"'${REACT_APP_BACKEND_URL}'"}' > public/config.json

# Build application
RUN npm run build

# Production stage
FROM nginx:stable-alpine

# Copy custom nginx config
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/nginx.conf /etc/nginx/conf.d/default.conf

# Copy built assets to nginx html directory
COPY --from=build-deps /usr/src/app/build /usr/share/nginx/html

# Create app directories and set permissions
RUN mkdir -p /usr/src/app/uploads \
    && mkdir -p /usr/src/app/public \
    && mkdir -p /var/cache/nginx \
    && mkdir -p /var/log/nginx \
    && chown -R nginx:nginx /usr/src/app \
    && chmod -R 755 /usr/src/app \
    && chown -R nginx:nginx /usr/share/nginx/html \
    && chmod -R 755 /usr/share/nginx/html \
    && chown -R nginx:nginx /var/cache/nginx \
    && chown -R nginx:nginx /var/log/nginx \
    && chown -R nginx:nginx /etc/nginx/conf.d \
    && touch /tmp/nginx.pid \
    && chown -R nginx:nginx /tmp/nginx.pid

# Switch to non-root user
USER nginx

# Expose port
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
