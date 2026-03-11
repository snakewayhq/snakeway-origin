# Build stage
FROM golang:1.26-alpine AS builder

WORKDIR /build

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go build -o origin-server ./cmd/origin-server
RUN go build -o origin-launcher ./cmd/origin-launcher

# ---- runtime ----
FROM alpine:3.19

RUN adduser -D origin

COPY --from=builder /build/origin-server /usr/local/bin/
COPY --from=builder /build/origin-launcher /usr/local/bin/

RUN mkdir -p /tmp

USER origin

ENTRYPOINT ["origin-launcher"]
