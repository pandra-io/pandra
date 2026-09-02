ARG BASE_IMAGE=ghcr.io/pandra-io/codex:latest
FROM ${BASE_IMAGE}

COPY agent.tar.gz /agent/agent.tar.gz

WORKDIR /agent/workspace
ENTRYPOINT ["pandra","run","--package","/agent/agent.tar.gz","--workspace","/agent/workspace"]
