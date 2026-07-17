FROM node:22-bookworm AS node_runtime

FROM ruby:3.4-bookworm

ARG CODEX_VERSION=0.144.4
ARG CLAUDE_CODE_VERSION=2.1.210
ARG PNPM_VERSION=10.33.4

COPY --from=node_runtime /usr/local/ /usr/local/
COPY package.json pnpm-lock.yaml /opt/pro-app-buildability/

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates \
      coreutils \
      curl \
      git \
      jq \
      libsqlite3-dev \
      perl \
      ripgrep \
    && npm install --global \
      "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
      "@openai/codex@${CODEX_VERSION}" \
      "pnpm@${PNPM_VERSION}" \
    && pnpm --dir /opt/pro-app-buildability install --frozen-lockfile --ignore-workspace \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

WORKDIR /repo
