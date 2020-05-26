FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-20407d81c1f45c2494920b33e0ac4318c5d9db97

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
