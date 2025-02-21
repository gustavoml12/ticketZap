FROM node:20-alpine as build-deps

# Set environment variables for better performance
ENV NODE_ENV=production
ENV DISABLE_ESLINT_PLUGIN=true
ENV GENERATE_SOURCEMAP=false
ENV CI=false

WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Tenta primeiro com npm install normal
RUN npm install --prefer-offline --no-audit || \
    # Se falhar, tenta com --legacy-peer-deps
    npm install --prefer-offline --no-audit --legacy-peer-deps || \
    # Se ainda falhar, remove o lock e tenta novamente
    (rm -f package-lock.json && npm install --no-audit --legacy-peer-deps)

# Copy source files
COPY . .

# Build with reduced memory usage
RUN NODE_OPTIONS="--max-old-space-size=2048" npm run build

# Production environment
FROM nginx:stable-alpine

# Copy custom nginx config
COPY nginx/nginx.conf /etc/nginx/conf.d/default.conf

# Copy built assets
COPY --from=build-deps /usr/src/app/build /usr/share/nginx/html

# Set permissions
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

USER nginx

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
