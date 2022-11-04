

locals {
  secrets = {
    am-env-secrets = {
      AM_PASSWORDS_AMADMIN_CLEAR = "amadmin user"
    },
    ds-passwords = {
      "dirmanager.pw" = "uid=admin user"
    },
    ds-env-secrets = {
      AM_STORES_APPLICATION_PASSWORD = "App str svc acct (uid=am-config,ou=admins,ou=am-config)"
      AM_STORES_CTS_PASSWORD         = "CTS svc acct (uid=openam_cts,ou=admins,ou=famrecords,ou=openam-session,ou=tokens)"
      AM_STORES_USER_PASSWORD        = "ID repo svc acct (uid=am-identity-bind-account,ou=admins,ou=identities)"
    }
  }
  ingresses = ["admin-ui", "idm", "am", "end-user-ui"]
}

data "kubernetes_secret_v1" "identity_platform" {
  for_each = contains(keys(var.cluster.helm), "identity-platform") ? (var.cluster.helm["identity-platform"]["deploy"] ? local.secrets : {}) : {}

  metadata {
    name      = each.key
    namespace = var.helm_metadata["identity-platform"].namespace
  }
}

data "kubernetes_ingress_v1" "identity_platform" {
  for_each = contains(keys(var.cluster.helm), "identity-platform") ? (var.cluster.helm["identity-platform"]["deploy"] ? toset(local.ingresses) : toset([])) : toset([])

  metadata {
    name      = each.key
    namespace = var.helm_metadata["identity-platform"].namespace
  }
}

locals {
  platform_passwords = var.helm_metadata["identity-platform"] == null ? null : <<-EOF
Relevent passwords:
%{~ for secret in keys(local.secrets) }
%{~ for key in keys(local.secrets[secret]) }
${contains(keys(data.kubernetes_secret_v1.identity_platform), secret) ? format("%s (%s)", nonsensitive(data.kubernetes_secret_v1.identity_platform[secret].data[key]), local.secrets[secret][key]) : ""}
%{~ endfor }
%{~ endfor }
EOF
  platform_urls = var.helm_metadata["identity-platform"] == null ? null : <<-EOF
Relevent URLs:
%{~ for ingress in local.ingresses }
${contains(keys(data.kubernetes_ingress_v1.identity_platform), ingress) ? format("https://%s%s", data.kubernetes_ingress_v1.identity_platform[ingress].spec[0].rule[0].host, data.kubernetes_ingress_v1.identity_platform[ingress].spec[0].rule[0].http[0].path[0].path) : ""}
%{~ endfor }
EOF
}

output "cluster_info" {
  value = <<-EOF
  =============================================================================

      ${var.cluster.type} cluster name: ${var.cluster.meta.cluster_name}
  ${var.cluster.type} cluster location: ${var.cluster.location.region}

  Execute the following to begin working with the new cluster:

  export KUBECONFIG=${var.kube_config["config_path"]}
  ${ local.platform_passwords != null || local.platform_urls != null ? "\n" : "" }${ local.platform_passwords != null ? local.platform_passwords : "" }${ local.platform_passwords != null && local.platform_urls != null ? "\n" : "" }${ local.platform_urls != null ? local.platform_urls : "" }
  =============================================================================
  EOF
}

