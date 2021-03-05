FROM gcr.io/forgerock-io/ig/pit1:7.1.0-2021-1-7660b2ac897f6b35aa8b2911f3203125adb72b4d

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
