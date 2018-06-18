FROM openjdk:11-jdk 


# Use this to directly add the opendj zip file
COPY opendj.zip /var/tmp/


WORKDIR /var/tmp/bootstrap

COPY bootstrap/ /var/tmp/bootstrap/

# The default BASE_DN of the directory tree.
ENV BASE_DN o=userstore

RUN ./setup.sh

#####################  Runtime container ################
FROM openjdk:11-jdk 

COPY --from=0 /var/tmp/bootstrap/run/dsrs1 /opt/opendj/

RUN useradd -d /opt/opendj -G root -m -u 11111 forgerock \
    && apt-get update && apt-get install -y --no-install-recommends dumb-init vim
   

WORKDIR /opt/opendj 


# This is the default location where secrets should be mounted.
ENV SECRET_PATH /var/run/secrets/opendj
# Path to secret file that contains the cn=Directory Manager password
# Used to configure the image
ENV DIR_MANAGER_PW_FILE /var/run/secrets/opendj/dirmanager.pw

# Path to the file that contains the uid=monitor user password for Prometheus metrics.
ENV MONITOR_PW_FILE /var/run/secrets/opendj/monitor.pw
# Paths to the keystore and the keystore pin.
ENV KEYSTORE_FILE /var/run/secrets/opendj/keystore.pkcs12
ENV KEYSTORE_PIN_FILE /var/run/secrets/opendj/keystore.pin
ENV OPENDJ_JAVA_ARGS "-Xmx1024m"

COPY *.sh /opt/opendj/
COPY bootstrap/secrets/* /var/run/secrets/opendj/
COPY scripts/ /opt/opendj/scripts/ 

RUN chown -R forgerock:root /opt/opendj

USER 11111


ENTRYPOINT  ["/opt/opendj/docker-entrypoint.sh"]

CMD ["start"]