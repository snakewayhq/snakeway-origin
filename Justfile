#!/usr/bin/env just --justfile

image := "snakeway-origin:dev"

# Update dependencies.
update:
    go get -u ./...
    go mod tidy -v

generate-proto:
    @echo "Generate proto code..."
    ./generate-proto.sh

build:
    @echo "Ensure sock file exists for UDS"
    touch /tmp/snakeway-http.sock
    @echo "Build the server (http, https, ws, wss, grpc)..."
    go build -o origin-server ./cmd/origin-server
    @echo "Build the launcher"
    go build -o origin-launcher ./cmd/origin-launcher

launch: build
    ./origin-launcher

# Build docker image
docker-build:
    docker build -t {{image}} .

# Run container locally
docker-run: docker-build
    docker run \
        --rm \
        -e ORIGIN_BASE_PORT=4000 \
        -e TLS_CERT=/certs/server.pem \
        -e TLS_KEY=/certs/server.key \
        -v ../snakeway/tests/integration/certs:/certs:ro \
        -p 4000-4004:4000-4004 \
        -p 4443-4447:4443-4447 \
        -p 6051-6055:6051-6055 \
        {{image}}

# Test using the same tag GHCR will use
docker-tag: docker-build
    docker tag {{image}} ghcr.io/snakewayhq/snakeway-origin:latest