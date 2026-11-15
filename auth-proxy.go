package main

import (
	"crypto/subtle"
	"encoding/json"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"strings"
	"time"
)

func main() {
	token := os.Getenv("NXS_OLLAMA_TOKEN")
	if len(token) < 32 {
		log.Fatal("NXS_OLLAMA_TOKEN must be set to a random secret of at least 32 characters")
	}
	port := os.Getenv("SERVER_PORT")
	if port == "" {
		port = "8025"
	}
	certFile := os.Getenv("NXS_TLS_CERT_FILE")
	if certFile == "" {
		certFile = "/home/container/tls/fullchain.pem"
	}
	keyFile := os.Getenv("NXS_TLS_KEY_FILE")
	if keyFile == "" {
		keyFile = "/home/container/tls/privkey.pem"
	}
	listen := ":" + port
	target, _ := url.Parse("http://127.0.0.1:11434")
	proxy := httputil.NewSingleHostReverseProxy(target)
	proxy.FlushInterval = -1

	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		scheme, supplied, ok := strings.Cut(r.Header.Get("Authorization"), " ")
		if !ok || !strings.EqualFold(scheme, "Bearer") || subtle.ConstantTimeCompare([]byte(supplied), []byte(token)) != 1 {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusUnauthorized)
			_ = json.NewEncoder(w).Encode(map[string]string{"error": "unauthorized"})
			return
		}
		proxy.ServeHTTP(w, r)
	})

	server := &http.Server{
		Addr:              listen,
		Handler:           handler,
		ReadHeaderTimeout: 10 * time.Second,
		IdleTimeout:       120 * time.Second,
	}
	log.Printf("NXS authenticated HTTPS Ollama gateway listening on %s", listen)
	log.Fatal(server.ListenAndServeTLS(certFile, keyFile))
}
