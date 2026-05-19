# syntax=docker/dockerfile:1

FROM oven/bun:1 AS web-build
WORKDIR /app
COPY web/package.json web/bun.lock ./web/
WORKDIR /app/web
RUN bun install --frozen-lockfile
COPY web/ .
RUN bun run build

FROM golang:1.25 AS go-build
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
COPY --from=web-build /app/web/dist ./web/dist
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /usr/local/bin/wuphf ./cmd/wuphf

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
ENV PORT=7891 \
    WUPHF_NO_NEX=1 \
    WUPHF_ALLOW_REMOTE_WEBUI=1 \
    WUPHF_WEB_BIND_HOST=0.0.0.0
EXPOSE 7891
COPY --from=go-build /usr/local/bin/wuphf /usr/local/bin/wuphf
ENTRYPOINT ["/usr/local/bin/wuphf"]
CMD ["--no-open", "--no-nex", "--provider", "codex", "--web-port", "7891"]
