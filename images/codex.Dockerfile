ARG PANDRA_BASE=ghcr.io/pandra-io/pandra:latest
FROM ${PANDRA_BASE}

RUN apk add --no-cache curl libgcc libstdc++ \
    && curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh

ENV PATH="/root/.local/bin:${PATH}"
