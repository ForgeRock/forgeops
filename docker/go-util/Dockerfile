# Go utilities to encrypt passwords, strip passwords from config,etc
# These are temporarily in this repo and will be moved eventually.
#
# Build with docker build -t gcr.io/engineering-devops/go-util:7.0.0 go-util
ARG GO_APP_BASE=1.1.1-alpine3.10
ARG GO_BUILD_BASE=3.0.1-alpine3.10
# ---
# am-crypto Source
FROM gcr.io/fr-saas-registry/go-build-base:${GO_BUILD_BASE} AS am-crypto-source

ARG SERVICE="am-crypto"
ARG GOCACHE="/.gocache"
ARG GOPROXY

ENV GOCACHE=$GOCACHE

# Create go cache
RUN mkdir -p $GOCACHE

# Copy source code from working directory inherited from go-build-base, i.e.
# /go/src/github.com/ForgeCloud/saas/tree/master/services/forgecloud/default/go
COPY go/$SERVICE $SERVICE
COPY go/go.mod ./
COPY go/common common
RUN go mod download

WORKDIR ./$SERVICE

#---
# am-crypto Build
FROM am-crypto-source AS am-crypto-build

RUN mkdir -p /dist

# Build optimized binary for production runtime
RUN go build -v -o /dist/am-crypto am-crypto.go

# ---
# strip-encrypted-values Source
FROM gcr.io/fr-saas-registry/go-build-base:${GO_BUILD_BASE} AS strip-enc-values-source

ARG SERVICE="strip-encrypted-values"
ARG GOCACHE="/.gocache"
ENV GOCACHE=$GOCACHE

# Create go cache
RUN mkdir -p $GOCACHE

# Copy source code from working directory inherited from go-build-base, i.e.
# /go/src/github.com/ForgeCloud/saas/tree/master/services/forgecloud/default/go
RUN mkdir -p ../forgecloud/default/am
WORKDIR ../forgecloud/default/am
COPY go.mod strip-enc* ./

#---
# strip-encrypted-values Build
FROM strip-enc-values-source AS strip-enc-values-build

RUN mkdir -p /dist

RUN go test ./...

# Build optimized binary for production runtime
RUN go build -v -o /dist/strip-encrypted-values strip-encrypted-values.go

COPY --from=am-crypto-build /dist/am-crypto /dist/am-crypto

