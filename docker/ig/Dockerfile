FROM gcr.io/forgerock-io/ig:7.0.0-e895fded9709b1222de876faf09e0a06c66cd251

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock ./basic /var/ig

#COPY --chown=forgerock ./benchmark /var/ig
