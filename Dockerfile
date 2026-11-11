FROM ollama/ollama:latest

ENV HOME=/home/container \
    OLLAMA_MODELS=/home/container/.ollama/models

WORKDIR /home/container
