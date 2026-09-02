FROM ghcr.io/pandra-io/pandra:latest AS build

WORKDIR /agent/project
COPY agent.yaml .
RUN pandra build --file agent.yaml --output /agent/agent.tar.gz

FROM ghcr.io/pandra-io/claudecode:latest

RUN apk update && apk add --no-cache uv
RUN uv tool install mcp-server-time

COPY --from=build /agent/agent.tar.gz /agent/agent.tar.gz

WORKDIR /agent/workspace
ENTRYPOINT ["pandra","run","--package","/agent/agent.tar.gz","--workspace","/agent/workspace"]
