FROM golang:1.24-alpine AS auth-proxy-builder
WORKDIR /src
COPY auth-proxy.go .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /auth-proxy auth-proxy.go

FROM ollama/ollama:latest

# Keep Ollama's writable state in the Pterodactyl server volume.
ENV HOME=/home/container \
    USER=container \
    OLLAMA_MODELS=/home/container/.ollama/models

WORKDIR /home/container

COPY --from=auth-proxy-builder /auth-proxy /usr/local/bin/nxs-auth-proxy
COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
CMD ["serve"]
