ARG REPO=us-docker.pkg.dev/forgeops-public/images-base/am-config-upgrader
ARG TAG=latest

FROM ${REPO}:${TAG}

USER root
RUN chown 11111:11111 /home/forgerock

# CVE-2026-114938 (Java4Shell, FORGEOPS-7044): the base image's JDK predates
# the November 2026 fix (25.0.5.1+ on the 25 line), so disable the
# AVX-512-accelerated java.util.Base64 intrinsics until the base is rebuilt.
# No security benefit on ARM64 or on x86-64 without AVX-512 (the
# vulnerable path is the AVX-512 Base64 intrinsic), and there the flag
# costs some Base64 throughput; remove once the base image ships a patched
# JDK. JDK_JAVA_OPTIONS is consumed by the JDK 9+ java
# launcher itself -- the amupgrade launcher script execs `java` bare,
# reading no opts variable of its own; JDK_JAVA_OPTIONS prints a "NOTE:"
# line on startup, which is expected.
ENV JDK_JAVA_OPTIONS=-XX:-UseBASE64Intrinsics
