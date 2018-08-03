# Dockerfile to download artifacts from the ForgeRock maven repository
# Build this with:
# docker build --build-arg API_KEY=$API_KEY -t forgerock/downloader downloader
# See the download script.
FROM alpine:latest

ARG API_KEY

RUN apk add --update \
        bash \
        curl \
    && rm -rf /var/cache/apk/* \
    && echo $API_KEY >/api_key

COPY download /usr/bin/

ENTRYPOINT [ "/usr/bin/download", "-w" ]