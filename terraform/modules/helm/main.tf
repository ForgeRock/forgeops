# main.tf - helm module

locals {
  deploy_metrics_server = contains(keys(var.charts), "metrics-server") ? true : false
  values_metrics_server = <<-EOF
  # Values from terraform helm module
  priorityClassName: system-node-critical

  args:
    - --kubelet-preferred-address-types=InternalIP
    - --kubelet-insecure-tls

  service:
    labels:
      kubernetes.io/cluster-service: "true"
      kubernetes.io/name: "Metrics-server"
  EOF
}

resource "helm_release" "metrics_server" {
  count = local.deploy_metrics_server ? 1 : 0

  name                  = "metrics-server"
  repository            = "https://kubernetes-sigs.github.io/metrics-server"
  chart                 = "metrics-server"
  version               = "3.7.0"
  namespace             = "kube-system"
  reuse_values          = false
  reset_values          = true
  max_history           = 12
  render_subchart_notes = false
  timeout               = 600

  values = [local.values_metrics_server, var.charts["metrics-server"]["values"]]

  depends_on = []
}

locals {
  deploy_external_secrets = contains(keys(var.charts), "external-secrets") ? true : false
  values_external_secrets = <<-EOF
  # Values from terraform helm module
  EOF
}

resource "helm_release" "external_secrets" {
  count = local.deploy_external_secrets ? 1 : 0

  name                  = "external-secrets"
  repository            = "https://charts.external-secrets.io"
  chart                 = "external-secrets"
  version               = "0.6.0-rc1"
  namespace             = "external-secrets"
  create_namespace      = true
  reuse_values          = false
  reset_values          = true
  max_history           = 12
  render_subchart_notes = false
  timeout               = 600

  values = [local.values_external_secrets, var.charts["external-secrets"]["values"]]

  depends_on = []
}

locals {
  deploy_external_dns = contains(keys(var.charts), "external-dns") && contains(keys(var.chart_configs), "external-dns") ? (var.chart_configs["external-dns"]["deploy"] ? true : false) : false
  values_external_dns = <<-EOF
  # Values from terraform helm module
  image:
    registry: us.gcr.io
    repository: k8s-artifacts-prod/external-dns/external-dns
    tag: v0.12.2

  sources:
    - ingress

  dryRun: false

  loglevel: info

  policy: sync
  EOF
}

resource "helm_release" "external_dns" {
  count = local.deploy_external_dns ? 1 : 0

  name                  = "external-dns"
  repository            = contains(keys(var.chart_configs["external-dns"]), "repository") ? var.chart_configs["external-dns"]["repository"] : "https://charts.bitnami.com/bitnami"
  chart                 = "external-dns"
  version               = contains(keys(var.chart_configs["external-dns"]), "version") ? var.chart_configs["external-dns"]["version"] : "6.9.0"
  namespace             = "external-dns"
  create_namespace      = true
  reuse_values          = false
  reset_values          = true
  max_history           = 12
  render_subchart_notes = false
  timeout               = 600

  values = [local.values_external_dns, var.charts["external-dns"]["values"], contains(keys(var.chart_configs), "external-dns") ? (contains(keys(var.chart_configs["external-dns"]), "values") ? var.chart_configs["external-dns"]["values"] : "") : ""]

  depends_on = []
}

locals {
  deploy_ingress_nginx = contains(keys(var.charts), "ingress-nginx") && contains(keys(var.chart_configs), "ingress-nginx") ? (var.chart_configs["ingress-nginx"]["deploy"] ? true : false) : false
  values_ingress_nginx = <<-EOF
  # Values from terraform helm module
  controller:
    kind: Deployment
    replicaCount: 2
    service:
      type: LoadBalancer
      externalTrafficPolicy: Local
      omitClusterIP: true
    publishService:
      enabled: true
    stats:
      enabled: true
      service:
        omitClusterIP: true
  EOF
}

resource "helm_release" "ingress_nginx" {
  count = local.deploy_ingress_nginx ? 1 : 0

  name                  = "ingress-nginx"
  repository            = contains(keys(var.chart_configs["ingress-nginx"]), "repository") ? var.chart_configs["ingress-nginx"]["repository"] : "https://kubernetes.github.io/ingress-nginx"
  chart                 = "ingress-nginx"
  version               = contains(keys(var.chart_configs["ingress-nginx"]), "version") ? var.chart_configs["ingress-nginx"]["version"] : "4.1.1"
  namespace             = "ingress-nginx"
  create_namespace      = true
  reuse_values          = false
  reset_values          = true
  max_history           = 12
  render_subchart_notes = false
  timeout               = 600

  values = [local.values_ingress_nginx, var.charts["ingress-nginx"]["values"], contains(keys(var.chart_configs), "ingress-nginx") ? (contains(keys(var.chart_configs["ingress-nginx"]), "values") ? var.chart_configs["ingress-nginx"]["values"] : "") : ""]

  depends_on = [helm_release.external_dns]
}

locals {
  deploy_haproxy_ingress = contains(keys(var.charts), "haproxy-ingress") && contains(keys(var.chart_configs), "haproxy-ingress") ? (var.chart_configs["haproxy-ingress"]["deploy"] ? true : false) : false
  values_haproxy_ingress = <<-EOF
  # Values from terraform helm module
  controller:
    kind: Deployment
    replicaCount: 2
    service:
      type: LoadBalancer
      externalTrafficPolicy: Local
    publishService:
      enabled: true
    stats:
      enabled: true
    ingressClassResource:
      enabled: true
    #hostNetwork: true
  EOF
}

resource "helm_release" "haproxy_ingress" {
  count = local.deploy_haproxy_ingress ? 1 : 0

  name                  = "haproxy-ingress"
  repository            = contains(keys(var.chart_configs["haproxy-ingress"]), "repository") ? var.chart_configs["haproxy-ingress"]["repository"] : "https://haproxy-ingress.github.io/charts"
  chart                 = "haproxy-ingress"
  version               = contains(keys(var.chart_configs["haproxy-ingress"]), "version") ? var.chart_configs["haproxy-ingress"]["version"] : "0.14.0-beta.2" #"0.13.9"
  namespace             = "haproxy-ingress"
  create_namespace      = true
  reuse_values          = false
  reset_values          = true
  max_history           = 12
  render_subchart_notes = false
  timeout               = 600

  values = [local.values_haproxy_ingress, var.charts["haproxy-ingress"]["values"], contains(keys(var.chart_configs), "haproxy-ingress") ? (contains(keys(var.chart_configs["haproxy-ingress"]), "values") ? var.chart_configs["haproxy-ingress"]["values"] : "") : ""]

  depends_on = [helm_release.external_dns]
}

locals {
  deploy_cert_manager = contains(keys(var.charts), "cert-manager") && contains(keys(var.chart_configs), "cert-manager") ? (var.chart_configs["cert-manager"]["deploy"] ? true : false) : false
  values_cert_manager = <<-EOF
  # Values from terraform helm module
  global:
    leaderElection:
      namespace: cert-manager

  installCRDs: true

  featureGates: "ExperimentalCertificateSigningRequestControllers=true"

  ingressShim:
    defaultIssuerName: default-issuer
    defaultIssuerKind: ClusterIssuer

  prometheus:
    enabled: false
  EOF
}

resource "helm_release" "cert_manager" {
  count = local.deploy_cert_manager ? 1 : 0

  name                  = "cert-manager"
  repository            = "https://charts.jetstack.io"
  chart                 = "cert-manager"
  version               = contains(keys(var.chart_configs["cert-manager"]), "version") ? var.chart_configs["cert-manager"]["version"] : "v1.10.1"
  namespace             = "cert-manager"
  create_namespace      = true
  reuse_values          = false
  reset_values          = true
  max_history           = 12
  render_subchart_notes = false
  timeout               = 600

  values = [local.values_cert_manager, var.charts["cert-manager"]["values"], contains(keys(var.chart_configs), "cert-manager") ? (contains(keys(var.chart_configs["cert-manager"]), "values") ? var.chart_configs["cert-manager"]["values"] : "") : ""]

  depends_on = [helm_release.ingress_nginx, helm_release.haproxy_ingress, helm_release.external_dns]
}

locals {
  deploy_trust_manager = contains(keys(var.charts), "trust-manager") && contains(keys(var.chart_configs), "trust-manager") ? (var.chart_configs["trust-manager"]["deploy"] ? true : false) : false
  values_trust_manager = <<-EOF
  # Values from terraform helm module
  EOF
}

resource "helm_release" "trust_manager" {
  count = local.deploy_trust_manager ? 1 : 0

  name                  = "trust-manager"
  repository            = "https://charts.jetstack.io"
  chart                 = "trust-manager"
  version               = contains(keys(var.chart_configs["trust-manager"]), "version") ? var.chart_configs["trust-manager"]["version"] : "v0.3.0"
  namespace             = "cert-manager"
  create_namespace      = true
  reuse_values          = false
  reset_values          = true
  max_history           = 12
  render_subchart_notes = false
  timeout               = 600

  values = [local.values_trust_manager, var.charts["trust-manager"]["values"], contains(keys(var.chart_configs), "trust-manager") ? (contains(keys(var.chart_configs["trust-manager"]), "values") ? var.chart_configs["trust-manager"]["values"] : "") : ""]

  depends_on = [helm_release.ingress_nginx, helm_release.haproxy_ingress, helm_release.external_dns, helm_release.cert_manager]
}

locals {
  values_raw_cert_manager = <<-EOF
  # Values from terraform helm module
  resources:
    - apiVersion: cert-manager.io/v1
      kind: ClusterIssuer
      metadata:
        name: default-issuer
      spec:
        acme:
          # The ACME server URL.
          server: https://acme-v02.api.letsencrypt.org/directory
          #server: https://acme-staging-v02.api.letsencrypt.org/directory
          # Email address used for ACME registration.
          email: forgeops-team@forgerock.com
          # Name of a secret used to store the ACME account private key.
          privateKeySecretRef:
            name: letsencrypt-default
          solvers:
          - http01:
              ingress:
                class: ${local.ingressClass}
    - apiVersion: cert-manager.io/v1
      kind: ClusterIssuer
      metadata:
        name: letsencrypt-production
      spec:
        acme:
          # The ACME server URL.
          server: https://acme-v02.api.letsencrypt.org/directory
          # Email address used for ACME registration.
          email: forgeops-team@forgerock.com
          # Name of a secret used to store the ACME account private key.
          privateKeySecretRef:
            name: letsencrypt-production
          solvers:
          - http01:
              ingress:
                class: ${local.ingressClass}
    - apiVersion: cert-manager.io/v1
      kind: ClusterIssuer
      metadata:
        name: letsencrypt-staging
      spec:
        acme:
          # The ACME server URL.
          server: https://acme-staging-v02.api.letsencrypt.org/directory
          # Email address used for ACME registration.
          email: forgeops-team@forgerock.com
          # Name of a secret used to store the ACME account private key.
          privateKeySecretRef:
            name: letsencrypt-staging
          solvers:
          - http01:
              ingress:
                class: ${local.ingressClass}
  EOF
}

resource "helm_release" "raw_cert_manager" {
  count = local.deploy_cert_manager ? 1 : 0

  name                  = "raw-cert-manager"
  repository            = "https://bedag.github.io/helm-charts" # "https://charts.itscontained.io"
  chart                 = "raw"
  version               = "1.1.0" # "0.2.5"
  namespace             = "cert-manager"
  create_namespace      = true
  reuse_values          = false
  reset_values          = true
  max_history           = 12
  render_subchart_notes = false
  timeout               = 600

  values = [local.values_raw_cert_manager]

  depends_on = [helm_release.cert_manager]
}

locals {
  deploy_kube_prometheus_stack = contains(keys(var.charts), "kube-prometheus-stack") && contains(keys(var.chart_configs), "kube-prometheus-stack") ? (var.chart_configs["kube-prometheus-stack"]["deploy"] ? true : false) : false
  values_kube_prometheus_stack = <<-EOF
  # Values from terraform helm module
  EOF
}

resource "helm_release" "kube_prometheus_stack" {
  count = local.deploy_kube_prometheus_stack ? 1 : 0

  name                  = "kube-prometheus-stack"
  repository            = contains(keys(var.chart_configs["kube-prometheus-stack"]), "repository") ? var.chart_configs["kube-prometheus-stack"]["repository"] : "https://prometheus-community.github.io/helm-charts"
  chart                 = "kube-prometheus-stack"
  version               = contains(keys(var.chart_configs["kube-prometheus-stack"]), "version") ? var.chart_configs["prometheus"]["version"] : "40.3.1"
  namespace             = "kube-prometheus-stack"
  create_namespace      = true
  reuse_values          = false
  reset_values          = true
  max_history           = 12
  render_subchart_notes = false
  timeout               = 600

  values = [local.values_kube_prometheus_stack, var.charts["kube-prometheus-stack"]["values"], contains(keys(var.chart_configs), "kube-prometheus-stack") ? (contains(keys(var.chart_configs["kube-prometheus-stack"]), "values") ? var.chart_configs["kube-prometheus-stack"]["values"] : "") : ""]

  depends_on = []
}

locals {
  deploy_elasticsearch = contains(keys(var.charts), "elasticsearch") && contains(keys(var.chart_configs), "elasticsearch") ? (var.chart_configs["elasticsearch"]["deploy"] ? true : false) : false
  values_elasticsearch = <<-EOF
  # Values from terraform helm module
  EOF
}

resource "helm_release" "elasticsearch" {
  count = local.deploy_elasticsearch ? 1 : 0

  name                  = "elasticsearch"
  repository            = contains(keys(var.chart_configs["elasticsearch"]), "repository") ? var.chart_configs["elasticsearch"]["repository"] : "https://helm.elastic.co"
  chart                 = "elasticsearch"
  version               = contains(keys(var.chart_configs["elasticsearch"]), "version") ? var.chart_configs["prometheus"]["version"] : "7.17.3"
  namespace             = "elk-stack" # "elasticsearch"
  create_namespace      = true
  reuse_values          = false
  reset_values          = true
  max_history           = 12
  render_subchart_notes = false
  timeout               = 600

  values = [local.values_elasticsearch, var.charts["elasticsearch"]["values"], contains(keys(var.chart_configs), "elasticsearch") ? (contains(keys(var.chart_configs["elasticsearch"]), "values") ? var.chart_configs["elasticsearch"]["values"] : "") : ""]

  depends_on = []
}

locals {
  deploy_logstash = contains(keys(var.charts), "logstash") && contains(keys(var.chart_configs), "logstash") ? (var.chart_configs["logstash"]["deploy"] ? true : false) : false
  values_logstash = <<-EOF
  # Values from terraform helm module
  EOF
}

resource "helm_release" "logstash" {
  count = local.deploy_logstash ? 1 : 0

  name                  = "logstash"
  repository            = contains(keys(var.chart_configs["logstash"]), "repository") ? var.chart_configs["logstash"]["repository"] : "https://helm.elastic.co"
  chart                 = "logstash"
  version               = contains(keys(var.chart_configs["logstash"]), "version") ? var.chart_configs["logstash"]["version"] : "7.17.3"
  namespace             = "elk-stack" # "logstash"
  create_namespace      = true
  reuse_values          = false
  reset_values          = true
  max_history           = 12
  render_subchart_notes = false
  timeout               = 600

  values = [local.values_logstash, var.charts["logstash"]["values"], contains(keys(var.chart_configs), "logstash") ? (contains(keys(var.chart_configs["logstash"]), "values") ? var.chart_configs["logstash"]["values"] : "") : ""]

  depends_on = []
}

locals {
  deploy_kibana = contains(keys(var.charts), "kibana") && contains(keys(var.chart_configs), "kibana") ? (var.chart_configs["kibana"]["deploy"] ? true : false) : false
  values_kibana = <<-EOF
  # Values from terraform helm module
  EOF
}

resource "helm_release" "kibana" {
  count = local.deploy_kibana ? 1 : 0

  name                  = "kibana"
  repository            = contains(keys(var.chart_configs["kibana"]), "repository") ? var.chart_configs["kibana"]["repository"] : "https://helm.elastic.co"
  chart                 = "kibana"
  version               = contains(keys(var.chart_configs["kibana"]), "version") ? var.chart_configs["kibana"]["version"] : "7.17.3"
  namespace             = "elk-stack" # "kibana"
  create_namespace      = true
  reuse_values          = false
  reset_values          = true
  max_history           = 12
  render_subchart_notes = false
  timeout               = 600

  values = [local.values_kibana, var.charts["kibana"]["values"], contains(keys(var.chart_configs), "kibana") ? (contains(keys(var.chart_configs["kibana"]), "values") ? var.chart_configs["kibana"]["values"] : "") : ""]

  depends_on = []
}

locals {
  deploy_raw_k8s_resources = contains(keys(var.charts), "raw-k8s-resources") ? true : false
  values_raw_k8s_resources = <<-EOF
  # Values from terraform helm module
  EOF
}

resource "helm_release" "raw_k8s_resources" {
  count = local.deploy_raw_k8s_resources ? 1 : 0

  name                  = "raw-k8s-resources"
  repository            = "https://bedag.github.io/helm-charts" # "https://charts.itscontained.io"
  chart                 = "raw"
  version               = "1.1.0" # "0.2.5"
  namespace             = "identity-platform"
  create_namespace      = true
  reuse_values          = false
  reset_values          = true
  force_update          = true
  max_history           = 12
  render_subchart_notes = false
  timeout               = 600

  values = [local.values_raw_k8s_resources, var.charts["raw-k8s-resources"]["values"]]

  depends_on = [helm_release.metrics_server, helm_release.external_secrets, helm_release.external_dns, helm_release.ingress_nginx, helm_release.haproxy_ingress, helm_release.cert_manager, helm_release.raw_cert_manager, helm_release.trust_manager, helm_release.kube_prometheus_stack, helm_release.elasticsearch, helm_release.logstash, helm_release.kibana]
}

locals {
  deploy_secret_agent = contains(keys(var.charts), "secret-agent") && contains(keys(var.chart_configs), "secret-agent") ? (var.chart_configs["secret-agent"]["deploy"] ? true : false) : false
  values_secret_agent = <<-EOF
  # Values from terraform helm module
  EOF
}

resource "helm_release" "secret_agent" {
  count = local.deploy_secret_agent ? 1 : 0

  name                  = "secret-agent"
  repository            = contains(keys(var.chart_configs["secret-agent"]), "repository") ? var.chart_configs["secret-agent"]["repository"] : "oci://us-docker.pkg.dev/forgeops-public/charts"
  chart                 = "secret-agent"
  version               = contains(keys(var.chart_configs["secret-agent"]), "version") ? var.chart_configs["secret-agent"]["version"] : "v1.1.6"
  namespace             = "secret-agent"
  create_namespace      = true
  reuse_values          = false
  reset_values          = true
  force_update          = true
  max_history           = 12
  render_subchart_notes = false
  timeout               = 600

  values = [local.values_secret_agent, var.charts["secret-agent"]["values"], contains(keys(var.chart_configs), "secret-agent") ? (contains(keys(var.chart_configs["secret-agent"]), "values") ? var.chart_configs["secret-agent"]["values"] : "") : ""]

  depends_on = [helm_release.raw_k8s_resources]
}

locals {
  deploy_ds_operator = contains(keys(var.charts), "ds-operator") && contains(keys(var.chart_configs), "ds-operator") ? (var.chart_configs["ds-operator"]["deploy"] ? true : false) : false
  values_ds_operator = <<-EOF
  # Values from terraform helm module
  EOF
}

resource "helm_release" "ds_operator" {
  count = local.deploy_ds_operator ? 1 : 0

  name                  = "ds-operator"
  repository            = contains(keys(var.chart_configs["ds-operator"]), "repository") ? var.chart_configs["ds-operator"]["repository"] : "oci://us-docker.pkg.dev/forgeops-public/charts"
  chart                 = "ds-operator"
  version               = contains(keys(var.chart_configs["ds-operator"]), "version") ? var.chart_configs["ds-operator"]["version"] : "v0.2.5"
  namespace             = "ds-operator"
  create_namespace      = true
  reuse_values          = false
  reset_values          = true
  force_update          = true
  max_history           = 12
  render_subchart_notes = false
  timeout               = 600

  values = [local.values_ds_operator, var.charts["ds-operator"]["values"], contains(keys(var.chart_configs), "ds-operator") ? (contains(keys(var.chart_configs["ds-operator"]), "values") ? var.chart_configs["ds-operator"]["values"] : "") : ""]

  depends_on = [helm_release.raw_k8s_resources]
}

locals {
   ingressClass = contains(keys(var.charts), "haproxy-ingress") && contains(keys(var.chart_configs), "haproxy-ingress") ? (var.chart_configs["haproxy-ingress"]["deploy"] ? "haproxy" : "nginx") : "nginx"

  deploy_identity_platform = contains(keys(var.charts), "identity-platform") && contains(keys(var.chart_configs), "identity-platform") ? (var.chart_configs["identity-platform"]["deploy"] ? true : false) : false
  values_identity_platform = <<-EOF
  # Values from terraform helm module
  timestamp: "${timestamp()}"

  platform:
    ingress:
      className: ${local.ingressClass}

  ldif_importer:
    enabled: ${local.deploy_ds_operator ? "false" : "true"}

  ${local.deploy_ds_operator ? <<-EOF
  ds_idrepo:
    kind: DirectoryService
    volumeClaimSpec:
      storageClassName: fast
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 10Gi
  ds_cts:
    kind: DirectoryService
    volumeClaimSpec:
      storageClassName: fast
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 10Gi
  EOF
  : ""
  }
  EOF
}

resource "helm_release" "identity_platform" {
  count = local.deploy_identity_platform ? 1 : 0

  name                  = "identity-platform"
  repository            = contains(keys(var.chart_configs["identity-platform"]), "repository") ? var.chart_configs["identity-platform"]["repository"] : "oci://us-docker.pkg.dev/forgeops-public/charts"
  chart                 = "identity-platform"
  version               = contains(keys(var.chart_configs["identity-platform"]), "version") ? var.chart_configs["identity-platform"]["version"] : null
  namespace             = "identity-platform"
  create_namespace      = true
  reuse_values          = false
  reset_values          = true
  force_update          = true
  max_history           = 12
  render_subchart_notes = false
  timeout               = 600

  values = [local.values_identity_platform, var.charts["identity-platform"]["values"], contains(keys(var.chart_configs), "identity-platform") ? (contains(keys(var.chart_configs["identity-platform"]), "values") ? var.chart_configs["identity-platform"]["values"] : "") : ""]

  depends_on = [helm_release.raw_k8s_resources, helm_release.secret_agent, helm_release.ds_operator]
}

