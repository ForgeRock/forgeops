FROM forgerock/opendj:latest

COPY schema /tmp/schema
COPY ldif /opt/opendj/bootstrap/extra/ldif
COPY setup-directory.sh /opt/opendj/bootstrap
COPY replicate.sh /opt/opendj/bootstrap
COPY rebuild.sh /opt/opendj/
