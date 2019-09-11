FROM gcr.io/forgerock-io/ig/pit1:7.0.0-912d21df1791fcfbe912369d4eaa037163e8cb86

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
#COPY --chown=forgerock ./basic /var/ig

COPY --chown=forgerock ./benchmark /var/ig