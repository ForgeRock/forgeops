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
  default = "amd64,arm64"
}

variable "PLATFORM_VERSION" {
  default = "7.5.0"
}

variable "PLATFORM_RELEASE" {
  #default = regex_replace(timestamp(), "[- TZ:]", "")
  default = ""
}

variable "BUILD_TAG" {
  default = "${PLATFORM_VERSION}-${PLATFORM_RELEASE},${PLATFORM_VERSION},latest"
}

variable "DS_FROM_IMAGE" {
  default = null
}

variable "DS_CTS_FROM_IMAGE" {
  default = null
}

variable "DS_IDREPO_FROM_IMAGE" {
  default = null
}

variable "DS_PROXY_FROM_IMAGE" {
  default = null
}

variable "AM_FROM_IMAGE" {
  default = null
}

variable "AMSTER_FROM_IMAGE" {
  default = null
}

variable "IDM_FROM_IMAGE" {
  default = null
}

variable "IG_FROM_IMAGE" {
  default = null
}

variable "LDIF_IMPORTER_FROM_IMAGE" {
  default = null
}

variable "RCS_AGENT_FROM_IMAGE" {
  default = null
}

variable "GIT_SERVER_FROM_IMAGE" {
  default = null
}

variable "ADMIN_UI_FROM_IMAGE" {
  default = null
}

variable "END_USER_UI_FROM_IMAGE" {
  default = null
}

variable "LOGIN_UI_FROM_IMAGE" {
  default = null
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
    "base",
  ]
}

group "all" {
  targets = [
    "base",
    "base-extra",
    "ui",
  ]
}

group "base" {
  targets = [
    "ds",
    "ds-cts",
    "ds-idrepo",
    "am",
    "amster",
    "idm",
    "ig",
    "ldif-importer",
  ]
}

group "base-extra" {
  targets = [
    "ds-proxy",
    "rcs-agent",
    "git-server",
  ]
}

group "ui" {
  targets = [
    "admin-ui",
    "end-user-ui",
    "login-ui",
  ]
}

target "base" {
  context = "."
  platforms = "${platforms("${BUILD_ARCH}")}"
  no-cache = NO_CACHE
  pull = PULL
  output = ["type=registry"]
  args = {
    FROM_IMAGE = null
    PLATFORM_VERSION = PLATFORM_VERSION
    PLATFORM_RELEASE = PLATFORM_RELEASE
  }
}

target "ds" {
  inherits = ["base"]

  context = "./ds/ds-new"
  dockerfile = "Dockerfile"
  args = {
    FROM_IMAGE = DS_FROM_IMAGE
  }

  tags = "${tags("${REGISTRY}", "${REPOSITORY}", "ds", "${BUILD_TAG}")}"
  cache-to = ["mode=max,type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/ds:build-cache"]
  cache-from = ["type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/ds:build-cache"]
}

target "ds-cts" {
  inherits = ["base"]

  context = "./ds"
  dockerfile = "cts/Dockerfile"
  args = {
    FROM_IMAGE = DS_CTS_FROM_IMAGE
  }

  tags = "${tags("${REGISTRY}", "${REPOSITORY}", "ds-cts", "${BUILD_TAG}")}"
  cache-to = ["mode=max,type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/ds-cts:build-cache"]
  cache-from = ["type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/ds-cts:build-cache"]
}

target "ds-idrepo" {
  inherits = ["base"]

  context = "./ds"
  dockerfile = "idrepo/Dockerfile"
  args = {
    FROM_IMAGE = DS_IDREPO_FROM_IMAGE
  }

  tags = "${tags("${REGISTRY}", "${REPOSITORY}", "ds-idrepo", "${BUILD_TAG}")}"
  cache-to = ["mode=max,type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/ds-idrepo:build-cache"]
  cache-from = ["type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/ds-idrepo:build-cache"]
}

target "ds-proxy" {
  inherits = ["base"]

  context = "./ds"
  dockerfile = "proxy/Dockerfile"
  args = {
    FROM_IMAGE = DS_PROXY_FROM_IMAGE
  }

  tags = "${tags("${REGISTRY}", "${REPOSITORY}", "ds-proxy", "${BUILD_TAG}")}"
  cache-to = ["mode=max,type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/ds-proxy:build-cache"]
  cache-from = ["type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/ds-proxy:build-cache"]
}

target "am" {
  inherits = ["base"]

  context = "./am"
  dockerfile = "Dockerfile"
  args = {
    FROM_IMAGE = AM_FROM_IMAGE
  }

  tags = "${tags("${REGISTRY}", "${REPOSITORY}", "am", "${BUILD_TAG}")}"
  cache-to = ["mode=max,type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/am:build-cache"]
  cache-from = ["type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/am:build-cache"]
}

target "amster" {
  inherits = ["base"]

  context = "./amster"
  dockerfile = "Dockerfile"
  args = {
    FROM_IMAGE = AMSTER_FROM_IMAGE
  }

  tags = "${tags("${REGISTRY}", "${REPOSITORY}", "amster", "${BUILD_TAG}")}"
  cache-to = ["mode=max,type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/amster:build-cache"]
  cache-from = ["type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/amster:build-cache"]
}

target "idm" {
  inherits = ["base"]

  context = "./idm"
  dockerfile = "Dockerfile"
  args = {
    FROM_IMAGE = IDM_FROM_IMAGE
  }

  tags = "${tags("${REGISTRY}", "${REPOSITORY}", "idm", "${BUILD_TAG}")}"
  cache-to = ["mode=max,type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/idm:build-cache"]
  cache-from = ["type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/idm:build-cache"]
}

target "ig" {
  inherits = ["base"]

  context = "./ig"
  dockerfile = "Dockerfile"
  args = {
    FROM_IMAGE = IG_FROM_IMAGE
  }

  tags = "${tags("${REGISTRY}", "${REPOSITORY}", "ig", "${BUILD_TAG}")}"
  cache-to = ["mode=max,type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/ig:build-cache"]
  cache-from = ["type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/ig:build-cache"]
}

target "ldif-importer" {
  inherits = ["base"]

  context = "./ldif-importer"
  dockerfile = "Dockerfile"
  args = {
    FROM_IMAGE = LDIF_IMPORTER_FROM_IMAGE
  }

  tags = "${tags("${REGISTRY}", "${REPOSITORY}", "ldif-importer", "${BUILD_TAG}")}"
  cache-to = ["mode=max,type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/ldif-importer:build-cache"]
  cache-from = ["type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/ldif-importer:build-cache"]
}

target "rcs-agent" {
  inherits = ["base"]

  context = "./rcs-agent"
  dockerfile = "Dockerfile"
  args = {
    FROM_IMAGE = RCS_AGENT_FROM_IMAGE
  }

  tags = "${tags("${REGISTRY}", "${REPOSITORY}", "rcs-agent", "${BUILD_TAG}")}"
  cache-to = ["mode=max,type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/rcs-agent:build-cache"]
  cache-from = ["type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/rcs-agent:build-cache"]
}

target "git-server" {
  inherits = ["base"]

  context = "./git-server"
  dockerfile = "Dockerfile"
  args = {
    FROM_IMAGE = GIT_SERVER_FROM_IMAGE
  }

  tags = "${tags("${REGISTRY}", "${REPOSITORY}", "git-server", "${BUILD_TAG}")}"
  cache-to = ["mode=max,type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/git-server:build-cache"]
  cache-from = ["type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/git-server:build-cache"]
}

target "admin-ui" {
  inherits = ["base"]

  context = "./admin-ui"
  dockerfile = "Dockerfile"
  args = {
    FROM_IMAGE = ADMIN_UI_FROM_IMAGE
  }

  tags = "${tags("${REGISTRY}", "${REPOSITORY}", "admin-ui", "${BUILD_TAG}")}"
  cache-to = ["mode=max,type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/admin-ui:build-cache"]
  cache-from = ["type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/admin-ui:build-cache"]
}

target "end-user-ui" {
  inherits = ["base"]

  context = "./end-user-ui"
  dockerfile = "Dockerfile"
  args = {
    FROM_IMAGE = END_USER_UI_FROM_IMAGE
  }

  tags = "${tags("${REGISTRY}", "${REPOSITORY}", "end-user-ui", "${BUILD_TAG}")}"
  cache-to = ["mode=max,type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/end-user-ui:build-cache"]
  cache-from = ["type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/end-user-ui:build-cache"]
}

target "login-ui" {
  inherits = ["base"]

  context = "./login-ui"
  dockerfile = "Dockerfile"
  args = {
    FROM_IMAGE = LOGIN_UI_FROM_IMAGE
  }

  tags = "${tags("${REGISTRY}", "${REPOSITORY}", "login-ui", "${BUILD_TAG}")}"
  cache-to = ["mode=max,type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/login-ui:build-cache"]
  cache-from = ["type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/login-ui:build-cache"]
}

