# Build stage
FROM node:20-alpine as build-deps

WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .

# Build with environment variables
ARG REACT_APP_BACKEND_URL=https://ticket.ebnez.com.br/api/
ENV REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL
ENV NODE_ENV=production
RUN echo '{"BACKEND_URL":"'${REACT_APP_BACKEND_URL}'"}' > public/config.json
RUN npm run build

# Production stage
FROM nginx:stable-alpine

# Install wget for healthcheck
RUN apk add --no-cache wget

# Copy nginx configuration and built files
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=build-deps /usr/src/app/build /usr/share/nginx/html

# Set up permissions
RUN chown -R nginx:nginx /var/cache/nginx /var/log/nginx /etc/nginx/nginx.conf /usr/share/nginx/html \
    && chmod -R 755 /usr/share/nginx/html \
    && touch /tmp/nginx.pid \
    && chown nginx:nginx /tmp/nginx.pid

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget --spider -q http://localhost:3000/health || exit 1

# Add Traefik labels
LABEL traefik.enable=true \
      traefik.http.middlewares.gzip.compress=true \
      traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https \
      traefik.http.routers.http-0-oc4cgcgos4wsg4skscwssggs.entryPoints=http \
      traefik.http.routers.http-0-oc4cgcgos4wsg4skscwssggs.middlewares=redirect-to-https \
      traefik.http.routers.http-0-oc4cgcgos4wsg4skscwssggs.rule="Host(`ticket.ebnez.com.br`) && PathPrefix(`/`)" \
      traefik.http.routers.http-0-oc4cgcgos4wsg4skscwssggs.service=http-0-oc4cgcgos4wsg4skscwssggs \
      traefik.http.routers.https-0-oc4cgcgos4wsg4skscwssggs.entryPoints=https \
      traefik.http.routers.https-0-oc4cgcgos4wsg4skscwssggs.middlewares=gzip \
      traefik.http.routers.https-0-oc4cgcgos4wsg4skscwssggs.rule="Host(`ticket.ebnez.com.br`) && PathPrefix(`/`)" \
      traefik.http.routers.https-0-oc4cgcgos4wsg4skscwssggs.service=https-0-oc4cgcgos4wsg4skscwssggs \
      traefik.http.routers.https-0-oc4cgcgos4wsg4skscwssggs.tls.certresolver=letsencrypt \
      traefik.http.routers.https-0-oc4cgcgos4wsg4skscwssggs.tls=true \
      traefik.http.services.http-0-oc4cgcgos4wsg4skscwssggs.loadbalancer.server.port=3000 \
      traefik.http.services.https-0-oc4cgcgos4wsg4skscwssggs.loadbalancer.server.port=3000

USER nginx
EXPOSE 3000
CMD ["nginx", "-g", "daemon off;"]
