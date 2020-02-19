FROM gcr.io/forgerock-io/ig/pit1:7.0.0-8d6ab69fad828eef62d68377e325c67162b0813f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
