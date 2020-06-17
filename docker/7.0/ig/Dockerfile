FROM gcr.io/forgerock-io/ig/pit1:7.0.0-8ed69c9db64d3ed19b804812dae4775864e8161a

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
