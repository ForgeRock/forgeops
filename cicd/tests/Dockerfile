# Dockerfile for smoke tests to be able to run in CI/CD systems or inside
# K8S cluster.

FROM alpine:3.5

RUN apk add --no-cache curl
RUN apk add --no-cache bash

RUN mkdir /tmp/testcases
COPY testcases/* /tmp/testcases/
COPY forgeops-smoke-test.sh /tmp
COPY run-full-smoke.sh /tmp

RUN chmod +x /tmp/forgeops-smoke-test.sh
RUN chmod +x /tmp/run-full-smoke.sh

ENTRYPOINT ["/bin/bash"]
