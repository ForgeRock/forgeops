FROM gcr.io/forgerock-io/ig/pit1:7.0.0-06496ee2767e5fb83b36834ca3cb25fe58522911

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
#COPY --chown=forgerock ./basic /var/ig

COPY --chown=forgerock ./benchmark /var/ig