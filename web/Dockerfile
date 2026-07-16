# Multi-stage build con Bun
FROM oven/bun:1.1-alpine AS builder

WORKDIR /app

# bun.lock* matchea el lockfile de texto (bun.lock, Bun 1.1) y el binario legacy
# (bun.lockb). El glob bun.lockb* NO matchea bun.lock → install sin lockfile.
COPY package.json bun.lock* ./
RUN bun install --frozen-lockfile

COPY . .

# Vite hornea las VITE_* en BUILD time (un SPA estático no lee env en runtime).
# Se reciben como build args y se exponen como ENV antes de `bun run build`;
# tienen precedencia sobre los valores de .env (que apuntan a localhost en dev).
ARG VITE_API_BASE_URL
ARG VITE_WS_URL
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL
ENV VITE_WS_URL=$VITE_WS_URL
RUN bun run build

# Stage de producción — serve estático
FROM oven/bun:1.1-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

COPY --from=builder /app/dist ./dist

CMD sh -c "bunx serve -s dist -l \${PORT:-5173}"
