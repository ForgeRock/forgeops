# outputs.tf - module outputs

output "metadata" {
  value = {
    "metrics-server"        = length(helm_release.metrics_server) > 0 ? helm_release.metrics_server[0].metadata[0] : null,
    "external-secrets"      = length(helm_release.external_secrets) > 0 ? helm_release.external_secrets[0].metadata[0] : null,
    "external-dns"          = length(helm_release.external_dns) > 0 ? helm_release.external_dns[0].metadata[0] : null,
    "ingress-nginx"         = length(helm_release.ingress_nginx) > 0 ? helm_release.ingress_nginx[0].metadata[0] : null
    "haproxy-ingress"       = length(helm_release.haproxy_ingress) > 0 ? helm_release.haproxy_ingress[0].metadata[0] : null
    "raw-haproxy-ingress"   = length(helm_release.raw_haproxy_ingress) > 0 ? helm_release.raw_haproxy_ingress[0].metadata[0] : null
    "cert-manager"          = length(helm_release.cert_manager) > 0 ? helm_release.cert_manager[0].metadata[0] : null
    "raw-cert-manager"      = length(helm_release.raw_cert_manager) > 0 ? helm_release.raw_cert_manager[0].metadata[0] : null
    "kube-prometheus-stack" = length(helm_release.kube_prometheus_stack) > 0 ? helm_release.kube_prometheus_stack[0].metadata[0] : null
    "elasticsearch"         = length(helm_release.elasticsearch) > 0 ? helm_release.elasticsearch[0].metadata[0] : null
    "logstash"              = length(helm_release.logstash) > 0 ? helm_release.logstash[0].metadata[0] : null
    "kibana"                = length(helm_release.kibana) > 0 ? helm_release.kibana[0].metadata[0] : null
    "raw-k8s-resources"     = length(helm_release.raw_k8s_resources) > 0 ? helm_release.raw_k8s_resources[0].metadata[0] : null
    "secret-agent"          = length(helm_release.secret_agent) > 0 ? helm_release.secret_agent[0].metadata[0] : null
    "ds-operator"           = length(helm_release.ds_operator) > 0 ? helm_release.ds_operator[0].metadata[0] : null
    "identity-platform"     = length(helm_release.identity_platform) > 0 ? helm_release.identity_platform[0].metadata[0] : null
  }
}

