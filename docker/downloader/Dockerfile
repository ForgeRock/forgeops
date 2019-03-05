# Dockerfile to download artifacts from the ForgeRock maven repository
# Build this with:
# docker build --build-arg API_KEY=$API_KEY -t forgerock/downloader downloader
# See the download script and ../README.md
#FROM alpine:latest

# Inherit from the gcloud container so we can use gcs as a cache.
FROM gcr.io/cloud-builders/gcloud:latest

ARG API_KEY

RUN echo $API_KEY >/api_key && \
    apt-get -q update && apt-get -q install unzip 

# RUN apk add --update \
#         wget \
#         bash \
#         curl \
#     && rm -rf /var/cache/apk/* \
#     && echo $API_KEY >/api_key

COPY download /usr/bin/

ENTRYPOINT [ "/usr/bin/download" ]