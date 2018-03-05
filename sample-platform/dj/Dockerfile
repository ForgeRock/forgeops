FROM quay.io/forgerock/opendj:latest

COPY schema /tmp/schema
COPY ldif /opt/opendj/bootstrap/extra/ldif
COPY post-install.sh /opt/opendj/bootstrap/userstore
COPY rebuild.sh /opt/opendj/
