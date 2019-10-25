FROM gcr.io/forgerock-io/ig:7.0.0-eb5e864dd70e7a129778df364401fc763892ac3e

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock ./basic /var/ig

#COPY --chown=forgerock ./benchmark /var/ig
