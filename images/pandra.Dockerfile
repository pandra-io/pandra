FROM golang:1.27-alpine AS build

WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /pandra ./cmd/pandra

FROM alpine:latest

RUN apk add --no-cache bash ca-certificates git ripgrep

COPY --from=build /pandra /usr/local/bin/pandra

CMD []
