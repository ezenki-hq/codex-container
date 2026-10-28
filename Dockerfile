
# Toolchain sources
FROM node:24-bookworm AS node
FROM golang:1.27-bookworm AS golang

# Main image
FROM python:3.13-bookworm

ARG VERSION=dev
ARG COMMIT=unknown
ARG DATE=unknown
ARG CODEX_VERSION=latest

LABEL org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${COMMIT}" \
      org.opencontainers.image.created="${DATE}"

ENV DEBIAN_FRONTEND=noninteractive

# Development dependencies
RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    git \
    git-lfs \
    openssh-client \
    build-essential \
    pkg-config \
    libssl-dev \
    cmake \
    clang \
    unzip \
    zip \
    jq \
    ripgrep \
    && rm -rf /var/lib/apt/lists/*

# Node.js and npm
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules

RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js \
        /usr/local/bin/npm \
    && ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js \
        /usr/local/bin/npx

# Go
COPY --from=golang /usr/local/go /usr/local/go

ENV PATH="/usr/local/go/bin:${PATH}"

# Docker CLI, Buildx and Compose
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg \
       -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable" \
       > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       docker-ce-cli \
       docker-buildx-plugin \
       docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Python tooling
RUN pip install --no-cache-dir uv

# Codex CLI
RUN npm install -g "@openai/codex@${CODEX_VERSION}"

# Non-root user
RUN groupadd -g 1000 codex \
    && useradd -m -u 1000 -g codex \
       -s /bin/bash codex \
    && mkdir -p /workspace \
       /home/codex/.codex \
       /home/codex/.agents/skills \
    && chown -R codex:codex \
       /workspace /home/codex

ENV HOME=/home/codex
ENV CODEX_HOME=/home/codex/.codex
ENV CARGO_HOME=/home/codex/.cargo
ENV RUSTUP_HOME=/home/codex/.rustup
ENV PATH="${CARGO_HOME}/bin:${PATH}"

USER codex

# Rust, Cargo, Clippy and rustfmt
RUN curl -fsSL https://sh.rustup.rs \
    | sh -s -- -y \
      --profile minimal \
      --no-modify-path \
    && rustup component add clippy rustfmt

WORKDIR /workspace

CMD ["sleep", "infinity"]
