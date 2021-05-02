FROM gcr.io/forgerock-io/ig/pit1:7.2.0-8df3edb7edffe8329b1cfdd7bbb3d9acf5ff05cb

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
