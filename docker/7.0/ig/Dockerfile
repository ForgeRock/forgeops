FROM gcr.io/forgerock-io/ig/pit1:7.1.2-48d8ec93b18104026ae48732eac46f3d28816f7a

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
