FROM node:lts-alpine3.12

WORKDIR /tmp
RUN npm install lodash@4.17.21

COPY generatePatch.js /tmp

ENTRYPOINT node generatePatch.js
