FROM node:lts-buster-slim

RUN mkdir /app && chmod -R 0775 /app && cd /app && npm install lodash@4.17.21
COPY applyPatch.js generatePatch.js entrypoint.sh /app/

USER 1000
ENV BASE_PATH=/mount
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]

