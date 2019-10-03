FROM gcr.io/forgerock-io/ig/pit1:7.0.0-932b0fcb01d6893fef2da37b04b065bac7d79715

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock ./basic /var/ig

#COPY --chown=forgerock ./benchmark /var/ig
