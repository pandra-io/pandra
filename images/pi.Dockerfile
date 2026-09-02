ARG PANDRA_BASE=ghcr.io/pandra-io/pandra:latest
FROM ${PANDRA_BASE}

RUN apk add --no-cache nodejs npm \
    && npm install -g --ignore-scripts @earendil-works/pi-coding-agent@latest \
    && npm cache clean --force
