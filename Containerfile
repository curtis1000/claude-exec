FROM node:lts-bookworm-slim

RUN npm install -g @anthropic-ai/claude-code@latest \
    && apt-get update \
    && apt-get install -y --no-install-recommends vim curl wget jq unzip ca-certificates git \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && ARCH=$(uname -m) \
    && if [ "$ARCH" = "x86_64" ]; then \
         curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; \
       elif [ "$ARCH" = "aarch64" ]; then \
         curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"; \
       fi \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws

WORKDIR /src
