FROM gcr.io/forgerock-io/ig/pit1:7.2.0-5b60f80e26b84750bafb92b9188bb5db8d28f932

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
