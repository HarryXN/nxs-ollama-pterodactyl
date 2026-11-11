#!/bin/sh
set -eu

export HOME=/home/container
export OLLAMA_MODELS="${OLLAMA_MODELS:-/home/container/.ollama/models}"

if [ "${1:-}" != "serve" ]; then
    exec /bin/ollama "$@"
fi

port="${SERVER_PORT:-8025}"
export OLLAMA_HOST="0.0.0.0:${port}"

/bin/ollama serve &
server_pid=$!

stop_server() {
    kill -TERM "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
}
trap stop_server INT TERM

echo "NXS: waiting for Ollama on port ${port}..."
until OLLAMA_HOST="127.0.0.1:${port}" /bin/ollama list >/dev/null 2>&1; do
    if ! kill -0 "$server_pid" 2>/dev/null; then
        status=1
        wait "$server_pid" || status=$?
        exit "$status"
    fi
    sleep 2
done

if ! OLLAMA_HOST="127.0.0.1:${port}" /bin/ollama show qwen3:4b >/dev/null 2>&1; then
    echo "NXS: downloading qwen3:4b; first startup may take several minutes..."
    OLLAMA_HOST="127.0.0.1:${port}" /bin/ollama pull qwen3:4b
fi

echo "NXS: qwen3:4b is ready."
wait "$server_pid"
