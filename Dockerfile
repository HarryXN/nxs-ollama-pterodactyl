FROM ollama/ollama:latest

ENV HOME=/home/container \
    OLLAMA_MODELS=/home/container/.ollama/models

WORKDIR /home/container

COPY entrypoint.sh /usr/local/bin/nxs-ollama-entrypoint
RUN chmod 755 /usr/local/bin/nxs-ollama-entrypoint

ENTRYPOINT ["/usr/local/bin/nxs-ollama-entrypoint"]
CMD ["serve"]
