# docker-bake.hcl

# Build configuration variables
variable "REGISTRY" {
  default = "us-docker.pkg.dev"
}

variable "REPOSITORY" {
  default = "forgeops-public/images"
}

variable "CACHE_REGISTRY" {
  default = REGISTRY
}

variable "CACHE_REPOSITORY" {
  default = REPOSITORY
}

variable "NO_CACHE" {
  default = false
}

variable "PULL" {
  default = true
}

variable "BUILD_ARCH" {
  default = "amd64"
}

variable "VERSION" {
  default = "1.5.20.35"
}

variable "PLATFORM_RELEASE" {
  default = ""
}

variable "BUILD_TAG" {
  default = "${VERSION},latest"
}

variable "FROM_TAG" {
  default = "${VERSION}"
}

# Helper functions
function "platforms" {
  params = [BUILD_ARCH]
  result = "${formatlist("linux/%s", "${split(",", "${BUILD_ARCH}")}")}"
}

function "tags" {
  params = [REGISTRY, REPOSITORY, image, BUILD_TAG]
  result = "${formatlist("${REGISTRY}/${REPOSITORY}/${image}:%s", "${split(",", "${BUILD_TAG}")}")}"
}

# Build targets
group "default" {
  targets = [
    "rcs",
  ]
}

target "rcs" {
  context = "."
  dockerfile = "Dockerfile"
  platforms = "${platforms("${BUILD_ARCH}")}"
  no-cache = NO_CACHE
  pull = PULL
  args = {
    TAG = FROM_TAG
  }
  tags = "${tags("${REGISTRY}", "${REPOSITORY}", "rcs", "${BUILD_TAG}")}"
  output = ["type=registry"]
  cache-to = ["mode=max,type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/rcs:build-cache"]
  cache-from = ["type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/rcs:build-cache"]
}
