# Multi-stage build con Bun
FROM oven/bun:1.1-alpine AS builder

WORKDIR /app

# bun.lock* matchea el lockfile de texto (bun.lock, Bun 1.1) y el binario legacy
# (bun.lockb). El glob bun.lockb* NO matchea bun.lock → install sin lockfile.
COPY package.json bun.lock* ./
RUN bun install --frozen-lockfile

COPY . .

# Vite hornea las VITE_* en BUILD time desde web/.env (un SPA estático no lee env
# en runtime). El deployer (deploy-all.sh) escribe web/.env con la API real +
# Firebase antes de este build.
RUN bun run build

# Stage de producción — serve estático
FROM oven/bun:1.1-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

COPY --from=builder /app/dist ./dist

CMD sh -c "bunx serve -s dist -l \${PORT:-5173}"
