FROM gcr.io/forgerock-io/ig:7.2.0-2021-8-a63b7211e462424e362dd2d89dc54288a079784e

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
