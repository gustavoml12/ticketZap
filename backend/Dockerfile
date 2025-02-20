# syntax=docker/dockerfile:1.7-labs

# Stage 1: Build the application
FROM node:20 AS build

WORKDIR /usr/src/app

# Copy package files first for better caching
COPY package*.json ./

# Install dependencies with npm install instead of npm ci
RUN --mount=type=cache,target=/root/.npm \
    npm install

# Copy the rest of the application
COPY . .

# Build the application
RUN npm run build

# Stage 2: Create the final image without source files
FROM ghcr.io/ticketz-oss/node

ARG TICKETZ_REGISTRY_URL

WORKDIR /usr/src/app

# Install curl for healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy only the necessary build artifacts from the build stage
COPY --from=build --parents \
  /usr/src/app/./dist \
  /usr/src/app/./node_modules \
  /usr/src/app/./package.json \
  /usr/src/app/./scripts \
  .

# Create necessary directories
RUN mkdir -p /usr/src/app/public /usr/src/app/private

ENV NODE_ENV=production
ENV PORT=3000
ENV TICKETZ_REGISTRY_URL=${TICKETZ_REGISTRY_URL}

EXPOSE 3000

# Set permissions
RUN chown -R node:node /usr/src/app

# Switch to non-root user
USER node

CMD dockerize -wait tcp://${DB_HOST}:5432 -timeout 60s \
  && npx sequelize db:migrate  --config dist/config/database.js --migrations-path dist/database/migrations \
  && ./scripts/load-retrieved.sh /retrieve; exit_code=$? \
  && if [ $exit_code -eq 1 ]; then npm run mark-seeds; exit 0; elif [ $exit_code -ge 100 ]; then exit 1; fi \
  && npx sequelize db:seed:all --config dist/config/database.js --seeders-path dist/database/seeds \
  && node dist/server.js
