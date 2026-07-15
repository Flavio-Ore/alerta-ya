FROM python:3.11-slim

# Instalar uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PROJECT_ENVIRONMENT=/app/.venv

# Instalar dependencias (sin dev group)
COPY pyproject.toml uv.lock* ./
RUN uv sync --frozen --no-dev

COPY src ./src

CMD sh -c ".venv/bin/uvicorn src.main:app --host 0.0.0.0 --port \${PORT:-8000}"
