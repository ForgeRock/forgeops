FROM gcr.io/forgerock-io/ig/pit1:7.0.0-7b0092195474e9db850ec85406f16c7d1f60c359

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
