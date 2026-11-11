FROM ollama/ollama:latest

ENV HOME=/home/container \
    USER=container \
    OLLAMA_MODELS=/home/container/.ollama/models

WORKDIR /home/container

COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
CMD ["serve"]
