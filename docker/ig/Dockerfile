FROM gcr.io/forgerock-io/ig:7.0.0-58010cde861640e516605232b16432c101d30752

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock ./basic /var/ig

#COPY --chown=forgerock ./benchmark /var/ig
