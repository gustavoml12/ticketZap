FROM node:20-alpine as build-deps

# Set environment variables for better performance
ENV NODE_ENV=development
ENV PATH /usr/src/app/node_modules/.bin:$PATH
ENV DISABLE_ESLINT_PLUGIN=true
ENV GENERATE_SOURCEMAP=false
ENV CI=false

WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install dependencies including react-scripts
RUN npm install --legacy-peer-deps && \
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

# Set permissions
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

USER nginx

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
