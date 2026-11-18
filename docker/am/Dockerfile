ARG REPO=us-docker.pkg.dev/forgeops-public/images-base/am
ARG TAG=latest

FROM ${REPO}:${TAG}

USER root
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends jq
USER 11111

ARG CONFIG_PROFILE=default
RUN echo "\033[0;36m*** Building '${CONFIG_PROFILE}' profile ***\033[0m"
COPY  --chown=forgerock:root config-profiles/${CONFIG_PROFILE}/ /home/forgerock/openam/

COPY --chown=forgerock:root *.sh /home/forgerock/

RUN mkdir -p /home/forgerock/logging

# Workaround for 8.1.0 to add missing SecurID auth module to amauthservice. This should be removed once the fix is in place in the base image.
# Remove workaround after the next Maj/Min release: FORGEOPS-6642
RUN if [ -f /home/forgerock/openam/config/services/realm/root/iplanetamauthservice/1.0/globalconfig/default.json ]; then \
        if ! grep -q "com.sun.identity.authentication.modules.securid.SecurID" /home/forgerock/openam/config/services/realm/root/iplanetamauthservice/1.0/globalconfig/default.json; then \
            sed -i -e 's/\"com.sun.identity.authentication.modules.sae.SAE\",/\"com.sun.identity.authentication.modules.sae.SAE\",\n      \"com.sun.identity.authentication.modules.securid.SecurID\",/' /home/forgerock/openam/config/services/realm/root/iplanetamauthservice/1.0/globalconfig/default.json; \
        fi \
    fi


# CVE-2026-114938 (Java4Shell, FORGEOPS-7044): the base image's JDK predates
# the November 2026 fix (25.0.5.1+ on the 25 line), so disable the
# AVX-512-accelerated java.util.Base64 intrinsics until the base is
# rebuilt. No security benefit on ARM64 or on x86-64 without AVX-512 (the
# vulnerable path is the AVX-512 Base64 intrinsic), and there the flag
# costs some Base64 throughput; remove once the base image ships a patched
# JDK.
ENV CATALINA_OPTS="${CATALINA_OPTS} -Dlogback.configurationFile=/home/forgerock/logging/logback.xml -XX:-UseBASE64Intrinsics"

WORKDIR /home/forgerock

# If you want to debug PingAM uncomment these lines:
#ENV JPDA_TRANSPORT=dt_socket
#ENV JPDA_ADDRESS *:9009
