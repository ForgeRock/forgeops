# deploy.tf - deploy components into cluster

resource "google_service_account" "external_secrets" {
  account_id = replace(substr("${local.cluster_name}-external-secrets", 0, 30), "/[^a-z0-9]$/", "")
  display_name = substr("External Secrets service account for k8s cluster: ${local.cluster_name}", 0, 100)
}

resource "google_project_iam_member" "external_secrets_admin" {
  role = "roles/secretmanager.admin"
  member = "serviceAccount:${google_service_account.external_secrets.email}"
  project = local.project
}

resource "google_project_iam_member" "external_secrets_service_account_token_creator" {
  role = "roles/iam.serviceAccountTokenCreator"
  member = "serviceAccount:${google_service_account.external_secrets.email}"
  project = local.project
}

resource "google_service_account_iam_member" "external_secrets_workload_identity_user" {
  service_account_id = google_service_account.external_secrets.name
  role = "roles/iam.workloadIdentityUser"
  member = "serviceAccount:${module.gke.identity_namespace}[external-secrets/external-secrets]"
}

resource "google_service_account" "external_dns" {
  account_id = replace(substr("${local.cluster_name}-external-dns", 0, 30), "/[^a-z0-9]$/", "")
  display_name = substr("ExternalDNS service account for k8s cluster: ${local.cluster_name}", 0, 100)
  #project = lookup(var.cluster.meta, "dns_zone_project", null)
}

resource "google_project_iam_member" "external_dns_admin" {
  role = "roles/dns.admin"
  member = "serviceAccount:${google_service_account.external_dns.email}"
  project = local.project
  #project = lookup(var.cluster.meta, "dns_zone_project", local.project)
}

#resource "google_service_account_key" "external_dns" {
#  service_account_id = google_service_account.external_dns.name
#}

resource "google_service_account_iam_member" "external_dns_workload_identity_user" {
  service_account_id = google_service_account.external_dns.name
  role = "roles/iam.workloadIdentityUser"
#  member = "serviceAccount:${local.project}.svc.id.goog[${module.helm.metadata["external-dns"]["namespace"]}/external-dns]"
  #member = "serviceAccount:${local.project}.svc.id.goog[external-dns/external-dns]"
  member = "serviceAccount:${module.gke.identity_namespace}[external-dns/external-dns]"
}

resource "google_compute_address" "ingress" {
  name = "${local.cluster_name}-${var.cluster.location.region}"
  address_type = "EXTERNAL"

  depends_on = [module.gke]
}

module "helm" {
  source = "../helm"

  chart_configs = var.cluster.helm

  charts = {
    "external-secrets" = {
      "values" = <<-EOF
      # Values from terraform GKE module
      serviceAccount:
        annotations:
          iam.gke.io/gcp-service-account: "${google_service_account.external_secrets.email}"
      EOF
    },
    "external-dns" = {
      "values" = <<-EOF
      # Values from terraform GKE module
      provider: google

      google:
        project: "${local.project}"

      txtOwnerId: "${local.cluster_name}.${var.cluster.location.region}"

      serviceAccount:
        annotations:
          iam.gke.io/gcp-service-account: "${google_service_account.external_dns.email}"
      EOF
    },
    "ingress-nginx" = {
      "values" = <<-EOF
      # Values from terraform GKE module
      controller:
        service:
          loadBalancerIP: ${google_compute_address.ingress.address}
      EOF
    },
    "haproxy-ingress" = {
      "values" = <<-EOF
      # Values from terraform GKE module
      controller:
        service:
          loadBalancerIP: ${google_compute_address.ingress.address}
      EOF
    },
    "cert-manager" = {
      "values" = <<-EOF
      # Values from terraform GKE module
      EOF
    },
    "kube-prometheus-stack" = {
      "values" = <<-EOF
      # Values from terraform GKE module
      EOF
    },
    "elasticsearch" = {
      "values" = <<-EOF
      # Values from terraform GKE module
      EOF
    },
    "logstash" = {
      "values" = <<-EOF
      # Values from terraform GKE module
      EOF
    },
    "kibana" = {
      "values" = <<-EOF
      # Values from terraform GKE module
      EOF
    },
    "raw-k8s-resources" = {
      "values" = <<-EOF
      # Values from terraform GKE module
      resources:
        - apiVersion: external-secrets.io/v1beta1
          kind: ClusterSecretStore
          metadata:
            name: default-secrets-store
          spec:
            provider:
              gcpsm:
                projectID: ${local.project}
                auth:
                  workloadIdentity:
                    clusterLocation: ${var.cluster.location.region}
                    clusterName: ${local.cluster_name}
                    clusterProjectID: ${local.project}
                    serviceAccountRef:
                      name: external-secrets
                      namespace: external-secrets
        - apiVersion: storage.k8s.io/v1
          kind: StorageClass
          metadata:
            name: fast
            #annotations:
            #  "storageclass.kubernetes.io/is-default-class": "true"
          parameters:
            type: pd-ssd
          provisioner: pd.csi.storage.gke.io
          reclaimPolicy: Delete
          volumeBindingMode: WaitForFirstConsumer
        - apiVersion: snapshot.storage.k8s.io/v1
          kind: VolumeSnapshotClass
          metadata:
            name: ds-snapshot-class
          driver: pd.csi.storage.gke.io
          deletionPolicy: Delete
      EOF
    }
  }

  depends_on = [module.gke, google_compute_address.ingress]
}

