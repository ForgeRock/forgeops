FROM gcr.io/forgerock-io/ig/pit1:7.1.2-502fac976e4fa92e542297529c756348cee0247f

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
