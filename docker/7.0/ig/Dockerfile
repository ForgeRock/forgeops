FROM gcr.io/forgerock-io/ig/pit1:7.1.0-2021-4-b3ad900c70a12da82525157a7f60c505047b1c24

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
