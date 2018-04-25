FROM postgres:9.6

ENV POSTGRES_PASSWORD password
ENV POSTGRES_DB openidm
ENV POSTGRES_USER openidm

COPY initdb.d /docker-entrypoint-initdb.d
