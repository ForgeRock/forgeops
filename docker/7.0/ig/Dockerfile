FROM gcr.io/forgerock-io/ig/pit1:7.1.0-2021-1-0f614323f211cc47699c9843cf33c812a26f65bf

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
