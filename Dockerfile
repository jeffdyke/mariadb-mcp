FROM python:3.11-slim AS uv_base

# Install build dependencies and curl for uv installer
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install uv
RUN curl -fsSL https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

WORKDIR /app

# Copy project files
COPY . .

# Install project dependencies into a local venv
RUN uv sync --no-dev

FROM python:3.11-slim AS uv_project
WORKDIR /app
# Copy venv and app from builder
COPY --from=uv_base /app/.venv /app/.venv
COPY --from=uv_base /app/src /app/src

FROM python:3.11-slim

WORKDIR /app
ENV PATH="/app/.venv/bin:${PATH}"

# Copy venv and app from builder
COPY --from=uv_project /app/.venv /app/.venv
COPY --from=uv_project /app/src /app/src

EXPOSE 9001

VOLUME [ "/var/log/bondlink" ]
# TODO Move to a path
ENTRYPOINT ["python", "src/server.py", "--host", "0.0.0.0", "--port", "9001", "--transport", "http", "--path", "/db-tools"]
