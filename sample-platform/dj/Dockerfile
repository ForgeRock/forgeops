FROM quay.io/forgerock/opendj:6.0.0

COPY schema /tmp/schema
COPY ldif /opt/opendj/bootstrap/extra/ldif
COPY post-install.sh /opt/opendj/bootstrap/userstore
COPY rebuild.sh /opt/opendj/
