FROM forgerock/opendj:latest

COPY schema /tmp/schema
COPY ldif /opt/opendj/bootstrap/extra/ldif
COPY setup.sh /opt/opendj/bootstrap
COPY replicate.sh /opt/opendj/
COPY rebuild.sh /opt/opendj/
