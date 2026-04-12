# Multi-stage build con Bun
FROM oven/bun:1.1-alpine AS builder

WORKDIR /app

COPY package.json bun.lockb* ./
COPY tsconfig.json ./
COPY prisma ./prisma/

RUN bun install --frozen-lockfile

COPY src ./src

RUN bun run prisma:generate && bun run build

# Stage de producción
FROM oven/bun:1.1-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/prisma ./prisma

EXPOSE 3000

CMD ["bun", "dist/index.js"]
