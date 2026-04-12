# Multi-stage build con Bun
FROM oven/bun:1.1-alpine AS builder

WORKDIR /app

COPY package.json bun.lockb* ./
RUN bun install --frozen-lockfile

COPY . .
RUN bun run build

# Stage de producción — serve estático
FROM oven/bun:1.1-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

COPY --from=builder /app/dist ./dist

EXPOSE 5173

CMD ["bunx", "serve", "-s", "dist", "-l", "5173"]
