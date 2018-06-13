FROM alpine:3.7

ENV PROCESSED_DASHBOARDS processed-dashboards
ENV OVERWRITE false

RUN apk update \
 && apk add --no-cache bash \
 && apk add --no-cache curl \
 && apk add --no-cache jq \
 && mkdir -p $PROCESSED_DASHBOARDS

COPY import-dashboards.sh .

ENTRYPOINT ["./import-dashboards.sh"]