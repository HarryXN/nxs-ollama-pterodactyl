#!/bin/sh
set -eu

sleep 1
echo "NXS: Pterodactyl entrypoint active."

export HOME=/home/container
export OLLAMA_MODELS="${OLLAMA_MODELS:-/home/container/.ollama/models}"

# Fail closed before starting any network-facing service if no secret was set.
token="${NXS_OLLAMA_TOKEN:-}"
if [ "${#token}" -lt 32 ]; then
    echo "NXS ERROR: set NXS_OLLAMA_TOKEN to a random secret of at least 32 characters."
    exit 1
fi

startup="${STARTUP:-${1:-serve}}"
if [ "$startup" != "serve" ]; then
    echo "NXS ERROR: startup command must be 'serve'; custom commands bypass the protected gateway."
    exit 1
fi

port="${SERVER_PORT:-8025}"
export OLLAMA_HOST="127.0.0.1:11434"
ollama_pid=""
proxy_pid=""

stop_children() {
    [ -z "$proxy_pid" ] || kill -TERM "$proxy_pid" 2>/dev/null || true
    [ -z "$ollama_pid" ] || kill -TERM "$ollama_pid" 2>/dev/null || true
    [ -z "$proxy_pid" ] || wait "$proxy_pid" 2>/dev/null || true
    [ -z "$ollama_pid" ] || wait "$ollama_pid" 2>/dev/null || true
}
trap stop_children INT TERM EXIT

echo "NXS: starting private Ollama backend on 127.0.0.1:11434..."
/bin/ollama serve &
ollama_pid=$!

echo "NXS: waiting for private Ollama backend..."
until OLLAMA_HOST="127.0.0.1:11434" /bin/ollama list >/dev/null 2>&1; do
    if ! kill -0 "$ollama_pid" 2>/dev/null; then
        status=1
        wait "$ollama_pid" || status=$?
        exit "$status"
    fi
    sleep 2
done

if ! OLLAMA_HOST="127.0.0.1:11434" /bin/ollama show qwen3:4b >/dev/null 2>&1; then
    echo "NXS: downloading qwen3:4b; first startup may take several minutes..."
    OLLAMA_HOST="127.0.0.1:11434" /bin/ollama pull qwen3:4b
fi

echo "NXS: qwen3:4b is ready."
echo "NXS: starting bearer-authenticated gateway on allocated port ${port}..."
SERVER_PORT="$port" /usr/local/bin/nxs-auth-proxy &
proxy_pid=$!
wait "$proxy_pid"
