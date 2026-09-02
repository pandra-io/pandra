FROM ghcr.io/pandra-io/claudecode:latest

# Install MCP server dependencies
RUN apk add --no-cache uv
RUN uv tool install mcp-server-time

# Install the agent package
RUN pandra install https://github.com/pandra-io/pandra/docs/examples/hello-world-image

WORKDIR /agent/workspace
ENTRYPOINT ["pandra","run","hello-world-time","--workspace","/agent/workspace"]
