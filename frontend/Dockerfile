FROM node:20-alpine as build-deps

# Set environment variables for better performance
ENV NODE_ENV=production
ENV PATH /usr/src/app/node_modules/.bin:$PATH
ENV DISABLE_ESLINT_PLUGIN=true
ENV GENERATE_SOURCEMAP=false
ENV CI=false

WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install dependencies with specific ajv version
RUN npm install --legacy-peer-deps && \
    npm install ajv@8.12.0 && \
    npm install react-scripts@5.0.1 -g && \
    npm cache clean --force

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

# Create directories for media with correct permissions
RUN mkdir -p /usr/share/nginx/html/uploads \
    && mkdir -p /usr/share/nginx/html/public \
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
