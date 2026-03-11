package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"strconv"
	"syscall"
	"time"
)

func envOrDefault(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func envInt(key string, def int) int {
	if v := os.Getenv(key); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			return n
		}
	}
	return def
}

func main() {
	const binary = "origin-server"

	count := envInt("ORIGIN_COUNT", 5)
	basePort := envInt("ORIGIN_BASE_PORT", 4000)
	tlsCert := envOrDefault("TLS_CERT", "/certs/server.pem")
	tlsKey := envOrDefault("TLS_KEY", "/certs/server.key")

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	var procs []*exec.Cmd

	for i := 0; i < count; i++ {
		port := basePort + i

		cmd := exec.CommandContext(
			ctx,
			binary,
			"-instance-id", fmt.Sprint(i),
			"-port", fmt.Sprint(port),
			"-tls-cert", tlsCert,
			"-tls-key", tlsKey,
		)

		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr

		log.Printf("starting server on port %d", port)
		if err := cmd.Start(); err != nil {
			log.Fatalf("failed to start server: %v", err)
		}

		procs = append(procs, cmd)
		// avoid thundering herd
		time.Sleep(100 * time.Millisecond)
	}

	<-ctx.Done()
	log.Println("shutting down children...")

	for _, p := range procs {
		_ = p.Process.Signal(syscall.SIGTERM)
	}

	time.Sleep(500 * time.Millisecond)
}
