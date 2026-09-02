ARG PANDRA_BASE=ghcr.io/pandra-io/pandra:latest
FROM ${PANDRA_BASE}

RUN apk add --no-cache libgcc libstdc++ wget \
    && wget -O /etc/apk/keys/claude-code.rsa.pub https://downloads.claude.ai/keys/claude-code.rsa.pub \
    && echo "https://downloads.claude.ai/claude-code/apk/latest" >> /etc/apk/repositories \
    && apk add --no-cache claude-code

ENV IS_SANDBOX=1
