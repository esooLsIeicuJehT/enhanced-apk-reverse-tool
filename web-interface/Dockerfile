FROM node:20-alpine AS builder

WORKDIR /app
COPY package.json ./
RUN npm install --no-audit --no-fund
COPY public ./public
COPY src ./src
COPY tsconfig.json ./tsconfig.json
RUN npm run build

FROM nginxinc/nginx-unprivileged:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build /usr/share/nginx/html

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget --quiet --spider http://127.0.0.1:8080/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
