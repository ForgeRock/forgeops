FROM node:lts-alpine3.12

WORKDIR /tmp
RUN npm install lodash@4.17.21

COPY applyPatch.js /tmp

ENTRYPOINT node applyPatch.js
