# Amster Container that configures AM.
#
#
FROM adoptopenjdk:8-jre-hotspot

ADD amster.zip /var/tmp/

RUN apt-get update && apt-get install -y unzip curl && \
    useradd -ms /bin/bash forgerock --gid 0 --uid 11111 && \
    unzip /var/tmp/amster.zip -d /opt/amster

COPY *.sh /opt/amster/
# put these in the path as well - for convenience.
COPY *.sh /usr/local/bin/

# git is added to the container so we can optionally execute git commit, git push, etc.
RUN chmod 775 /opt/amster/amster \
    && chown -R forgerock:0 /opt

WORKDIR /opt/amster

USER 11111

ENTRYPOINT ["/opt/amster/docker-entrypoint.sh"]

CMD ["configure"]