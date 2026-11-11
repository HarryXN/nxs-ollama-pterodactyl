FROM ollama/ollama:latest

ENV HOME=/home/container \
    USER=container \
    OLLAMA_MODELS=/home/container/.ollama/models

WORKDIR /home/container

RUN apt-get update \
    && apt-get install -y --no-install-recommends tini \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
