# How to Retrieve SBOMs for ForgeOps Images

SBOMs (Software Bills of Materials) document all components bundled in a Docker image.
ForgeOps publishes SBOMs as downloadable files in SPDX and CycloneDX formats, for manual review or compliance workflows.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Step 1: Identify Your Image Tag](#step-1-identify-your-image-tag)
- [Step 2: Download an SBOM](#step-2-download-an-sbom)
    - [Browse available SBOMs](#browse-available-sboms)
    - [Download via curl](#download-via-curl)
- [SBOM Formats](#sbom-formats)
    - [CycloneDX](#cyclonedx)
    - [SPDX](#spdx)
    - [Choosing a format](#choosing-a-format)

---

## Prerequisites

No special tools are required to download SBOMs.

For the optional inspection commands in the [SBOM Formats](#sbom-formats) section, the following tools are needed:

| Tool | Purpose | 
|---|---|
| [`cyclonedx`](https://github.com/CycloneDX/cyclonedx) | Validate and inspect CycloneDX files |
| [`pyspdxtools`](https://github.com/spdx/tools-python) | Validate SPDX files |
| [`jq`](https://jqlang.org/) | Parse JSON |

---

## Step 1: Identify Your Image Tag

Retrieve the exact image tag using one of:

**From the ForgeOps CLI:**

```sh
bin/forgeops info --list-releases --json | jq -r '.ds["8.1"]["8.1.0"]'
# Output: 8.1.0-202605280539
```

**From the releases page:** Browse [releases.forgeops.com](http://releases.forgeops.com/).

---

## Step 2: Download an SBOM

SBOMs are available at the following URL structure:

```
http://releases.forgeops.com/sbom/PRODUCT_NAME/VERSION/TAG.ARCH.FORMAT.json
```

| Variable       | Values |
|----------------|--------|
| `PRODUCT_NAME` | `admin-ui`, `am`, `amster`, `am-config-upgrader`, `ds`, `end-user-ui`, `idm`, `ig`, `login-ui` |
| `VERSION`      | `MAJOR.MINOR.PATCH` (e.g. `8.1.0`) |
| `TAG`          | Full image tag (e.g. `8.1.0-202605280539`) |
| `ARCH`         | `amd64` or `arm64` |
| `FORMAT`       | `cyclonedx` or `spdx` |

**Example:**

[http://releases.forgeops.com/sbom/ds/8.1.0/8.1.0-202605280539.amd64.cyclonedx.json](http://releases.forgeops.com/sbom/ds/8.1.0/8.1.0-202605280539.amd64.cyclonedx.json)


### Browse available SBOMs

Visit [releases.forgeops.com/sbom](http://releases.forgeops.com/sbom) to browse all published SBOMs.

### Download via curl

```sh
# Define what needed
PRODUCT_NAME="ds"
VERSION="8.1.0"
TAG="8.1.0-202605280539"
ARCH="amd64"  # or arm64
FORMAT="cyclonedx"  # or spdx

# Download the SBOMs file
curl -O "http://releases.forgeops.com/sbom/${PRODUCT_NAME}/${VERSION}/${TAG}.${ARCH}.${FORMAT}.json"

# File downloaded
$ ls
8.1.0-202605280539.amd64.cyclonedx.json
```

---

## SBOM Formats

### CycloneDX

CycloneDX is an OWASP standard focused on security use cases. It is designed for vulnerability management, license compliance, and supply chain risk analysis.

**Common uses:**
- Feed into vulnerability scanners (e.g. [Grype](https://github.com/anchore/grype), [Trivy](https://trivy.dev/), [OWASP Dependency-Track](https://dependencytrack.org/))
- Track known CVEs across components
- Enforce license policies in CI/CD pipelines

**Official documentation:** [cyclonedx.org](https://cyclonedx.org/docs/1.6/)

**Quick inspection with `cyclonedx`:**

```sh
# Validate
cyclonedx validate --input-file 8.1.0-202605280539.amd64.cyclonedx.json --input-format json

# List components
cyclonedx convert \
  --input-file 8.1.0-202605280539.amd64.cyclonedx.json \
  --input-format json \
  --output-format csv \
  | column -t -s,
```

---

### SPDX

SPDX (Software Package Data Exchange) is an ISO standard (ISO/IEC 5962:2021) focused on license compliance and provenance tracking. It is widely used in open source and legal contexts.

**Common uses:**
- Audit open source license obligations
- Satisfy regulatory or contractual SBOM requirements (e.g. US Executive Order 14028)
- Ingest into license compliance tools (e.g. [FOSSA](https://fossa.com/), [FOSSology](https://www.fossology.org/))

**Official documentation:** [spdx.github.io/spdx-spec](https://spdx.github.io/spdx-spec/v2.3/)

**Quick inspection with `pyspdxtools`:**

Install via pip (not Homebrew):
```sh
pip install spdx-tools
```

```sh
# Download the SPDX file first
curl -O "http://releases.forgeops.com/sbom/${PRODUCT_NAME}/${VERSION}/${TAG}.${ARCH}.spdx.json"

# Validate
pyspdxtools -i 8.1.0-202605280539.amd64.spdx.json

# List packages and their licenses
jq '.packages[] | {name: .name, version: .versionInfo, license: .licenseConcluded}' 8.1.0-202605280539.amd64.spdx.json
```

---

### Choosing a format

| Use case | Recommended format |
|---|---|
| Vulnerability scanning | CycloneDX |
| License compliance | SPDX |
| Regulatory/contractual requirements | SPDX (ISO standard) |
| CI/CD security gates | CycloneDX |