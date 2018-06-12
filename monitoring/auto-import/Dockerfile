FROM alpine:3.7

ENV DASHBOARDS dashboards
ENV PROCESSED_DASHBOARDS processed-dashboards
ENV OVERWRITE false

RUN apk update \
 && apk add --no-cache bash \
 && apk add --no-cache curl \
 && apk add --no-cache jq \
 && mkdir -p $DASHBOARDS $PROCESSED_DASHBOARDS

COPY dashboards/*.json $DASHBOARDS/
COPY import-dashboards.sh .

ENTRYPOINT ["./import-dashboards.sh"]