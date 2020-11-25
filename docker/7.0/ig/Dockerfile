FROM gcr.io/forgerock-io/ig/pit1:7.1.0-de5e61d423975f595c896abd659bb2863e18acbb

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
