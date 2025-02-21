FROM node:20-alpine as build-deps

# Set build arguments
ARG NODE_ENV
ARG DISABLE_ESLINT_PLUGIN
ARG GENERATE_SOURCEMAP
ARG CI
ARG NODE_OPTIONS

# Set environment variables from build args
ENV NODE_ENV=$NODE_ENV
ENV DISABLE_ESLINT_PLUGIN=$DISABLE_ESLINT_PLUGIN
ENV GENERATE_SOURCEMAP=$GENERATE_SOURCEMAP
ENV CI=$CI
ENV NODE_OPTIONS=$NODE_OPTIONS
ENV PATH /usr/src/app/node_modules/.bin:$PATH

WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install dependencies with cache
RUN --mount=type=cache,target=/root/.npm \
    npm install --legacy-peer-deps && \
    npm install ajv@8.12.0 && \
    npm install react-scripts@5.0.1 -g && \
    npm cache clean --force

# Copy source files
COPY . .

# Build with optimizations
RUN npm run build

# Production environment
FROM nginx:stable-alpine

# Remove default nginx config
RUN rm -rf /etc/nginx/conf.d/* && \
    rm -rf /etc/nginx/nginx.conf

# Copy custom nginx config
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Copy built assets to nginx html directory
COPY --from=build-deps /usr/src/app/build /usr/share/nginx/html

# Create app directories and set permissions
RUN mkdir -p /usr/src/app/uploads \
    && mkdir -p /usr/src/app/public \
    && chown -R nginx:nginx /usr/src/app \
    && chmod -R 755 /usr/src/app \
    && chown -R nginx:nginx /usr/share/nginx/html \
    && chmod -R 755 /usr/share/nginx/html \
    && chown -R nginx:nginx /var/cache/nginx \
    && chown -R nginx:nginx /var/log/nginx \
    && chown -R nginx:nginx /etc/nginx \
    && touch /tmp/nginx.pid \
    && chown -R nginx:nginx /tmp/nginx.pid

# Set nginx user as default
USER nginx

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
