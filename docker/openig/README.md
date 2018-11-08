# Dockerfile for OpenIG

To build:

`docker build -t forgerock/openig:latest . `

To run:

`docker run -p 8080:8080 -it forgerock/openig`

To use the sample configuration, mount the samples-config directory on /var/openig in the container:

`docker run --rm -p 28080:8080 -v `pwd`/sample-config:/var/openig -it forgerock/openig`
