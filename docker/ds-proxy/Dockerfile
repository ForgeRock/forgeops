FROM us-docker.pkg.dev/forgeops-public/images-base/ds:latest

# CVE-2026-114938 (Java4Shell, FORGEOPS-7044): the base image's JDK predates
# the November 2026 fix (25.0.5.1+ on the 25 line), so disable the
# AVX-512-accelerated java.util.Base64 intrinsics until the base is rebuilt.
# No security benefit on ARM64 or on x86-64 without AVX-512 (the
# vulnerable path is the AVX-512 Base64 intrinsic), and there the flag
# costs some Base64 throughput; remove once the base image ships a patched
# JDK. DS_JAVA_ADDITIONAL_ARGS is the extension slot in the
# base's env.sh DEFAULT_DS_JAVA_ARGS; a runtime override replaces this
# value -- include the flag there too.
ENV DS_JAVA_ADDITIONAL_ARGS=-XX:-UseBASE64Intrinsics

COPY debian-buster-sources.list /etc/apt/sources.list

# If you want to update any o/s software, or require root access, uncomment the lines below
# Ensure that the /opt/opendj is owned by forgeorock:root
# USER root
# RUN chown -R forgerock:root /opt/opendj
# USER forgerock
WORKDIR  /opt/opendj

COPY --chown=forgerock:root common  /opt/opendj/
COPY --chown=forgerock:root proxy  /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts

# This primes the idrepo datastore with the required base policy entries in ou=am-config
# This can be removed once PingAM can create these itself. See AME-19010
RUN chmod +w  template/setup-profiles/AM/config/6.5/base-entries.ldif && cat scripts/external-am-datastore.ldif >> template/setup-profiles/AM/config/6.5/base-entries.ldif

RUN bin/setup.sh && \
    bin/relax-security-settings.sh  && \
    rm bin/setup.sh bin/relax-security-settings.sh
