# deploy.tf - deploy components into cluster

locals {
  eks_registries = {
    "af-south-1"     = "877085696533.dkr.ecr.af-south-1.amazonaws.com"
    "ap-east-1"      = "800184023465.dkr.ecr.ap-east-1.amazonaws.com"
    "ap-northeast-1" = "602401143452.dkr.ecr.ap-northeast-1.amazonaws.com"
    "ap-northeast-2" = "602401143452.dkr.ecr.ap-northeast-2.amazonaws.com"
    "ap-northeast-3" = "602401143452.dkr.ecr.ap-northeast-3.amazonaws.com"
    "ap-south-1"     = "602401143452.dkr.ecr.ap-south-1.amazonaws.com"
    "ap-southeast-1" = "602401143452.dkr.ecr.ap-southeast-1.amazonaws.com"
    "ap-southeast-2" = "602401143452.dkr.ecr.ap-southeast-2.amazonaws.com"
    "ca-central-1"   = "602401143452.dkr.ecr.ca-central-1.amazonaws.com"
    "cn-north-1"     = "918309763551.dkr.ecr.cn-north-1.amazonaws.com.cn"
    "cn-northwest-1" = "961992271922.dkr.ecr.cn-northwest-1.amazonaws.com.cn"
    "eu-central-1"   = "602401143452.dkr.ecr.eu-central-1.amazonaws.com"
    "eu-north-1"     = "602401143452.dkr.ecr.eu-north-1.amazonaws.com"
    "eu-south-1"     = "590381155156.dkr.ecr.eu-south-1.amazonaws.com"
    "eu-west-1"      = "602401143452.dkr.ecr.eu-west-1.amazonaws.com"
    "eu-west-2"      = "602401143452.dkr.ecr.eu-west-2.amazonaws.com"
    "eu-west-3"      = "602401143452.dkr.ecr.eu-west-3.amazonaws.com"
    "me-south-1"     = "558608220178.dkr.ecr.me-south-1.amazonaws.com"
    "sa-east-1"      = "602401143452.dkr.ecr.sa-east-1.amazonaws.com"
    "us-east-1"      = "602401143452.dkr.ecr.us-east-1.amazonaws.com"
    "us-east-2"      = "602401143452.dkr.ecr.us-east-2.amazonaws.com"
    "us-gov-east-1"  = "151742754352.dkr.ecr.us-gov-east-1.amazonaws.com"
    "us-gov-west-1"  = "013241004608.dkr.ecr.us-gov-west-1.amazonaws.com"
    "us-west-1"      = "602401143452.dkr.ecr.us-west-1.amazonaws.com"
    "us-west-2"      = "602401143452.dkr.ecr.us-west-2.amazonaws.com"
  }
}

locals {
  values_aws_ebs_csi_driver = <<-EOF
  # Values from terraform EKS module
  image:
    repository: ${lookup(local.eks_registries, var.cluster.location["region"], local.eks_registries["us-east-1"])}/eks/aws-ebs-csi-driver

  controller:
    serviceAccount:
      create: true
      name: ebs-csi-controller-sa
      annotations:
        eks.amazonaws.com/role-arn: "${module.iam_assumable_role_admin["aws-ebs-csi-driver"].iam_role_arn}"

  #storageClasses:
  # - name: fast
  #   annotations:
  #     storageclass.kubernetes.io/is-default-class: "true"
  #   volumeBindingMode: WaitForFirstConsumer
  EOF
}

resource "helm_release" "aws_ebs_csi_driver" {
  name = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart = "aws-ebs-csi-driver"
  version = "2.6.7"
  namespace = "kube-system"
  reuse_values = false
  reset_values = true
  max_history = 12
  render_subchart_notes = false
  timeout = 600

  values = [local.values_aws_ebs_csi_driver]

  depends_on = [module.eks, module.vpc, module.iam_assumable_role_admin["aws-ebs-csi-driver"], local_file.kube_config]
}

locals {
  values_snapshot_controller = <<-EOF
  # Values from terraform EKS module
  EOF
}

resource "helm_release" "snapshot_controller" {
  name = "snapshot-controller"
  repository = "https://piraeus.io/helm-charts"
  chart = "snapshot-controller"
  version = "1.5.1"
  namespace = "kube-system"
  reuse_values = false
  reset_values = true
  max_history = 12
  render_subchart_notes = false
  timeout = 600

  values = [local.values_snapshot_controller]

  depends_on = [module.eks, module.vpc, helm_release.aws_ebs_csi_driver, local_file.kube_config]
}

locals {
  values_aws_load_balancer_controller = <<-EOF
  # Values from terraform EKS module
  image:
    repository: ${lookup(local.eks_registries, var.cluster.location.region, local.eks_registries["us-east-1"])}/amazon/aws-load-balancer-controller

  clusterName: ${local.cluster_name}

  serviceAccount:
    name: aws-load-balancer-controller
    annotations:
      eks.amazonaws.com/role-arn: "${module.iam_assumable_role_admin["aws-load-balancer-controller"].iam_role_arn}"

  region: "${var.cluster.location.region}"

  vpcId: "${module.vpc.vpc_id}"

  podDisruptionBudget:
    maxUnavailable: 1
  EOF
}

resource "helm_release" "aws_load_balancer_controller" {
  name = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart = "aws-load-balancer-controller"
  version = "1.4.5"
  namespace = "kube-system"
  reuse_values = false
  reset_values = true
  max_history = 12
  render_subchart_notes = false
  timeout = 600

  values = [local.values_aws_load_balancer_controller]

  depends_on = [module.eks, module.vpc, module.iam_assumable_role_admin["aws-load-balancer-controller"], local_file.kube_config]
}

locals {
  values_cluster_autoscaler = <<-EOF
  # Values from terraform EKS module
  autoDiscovery:
    clusterName: ${local.cluster_name}

  awsRegion: "${var.cluster.location["region"]}"

  cloudProvider: aws

  rbac:
    create: true
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: "${module.iam_assumable_role_admin["cluster-autoscaler"].iam_role_arn}"
  EOF
}

resource "helm_release" "cluster_autoscaler" {
  name = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart = "cluster-autoscaler"
  version = "9.10.8"
  namespace = "kube-system"
  reuse_values = false
  reset_values = true
  max_history = 12
  render_subchart_notes = false
  timeout = 600

  values = [local.values_cluster_autoscaler]

  depends_on = [module.eks, module.vpc, module.iam_assumable_role_admin["cluster-autoscaler"], local_file.kube_config]
}

resource "aws_eip" "ingress" {
  #count = length(module.vpc.public_subnets)
  count = length(distinct(var.cluster.location.zones))

  vpc = true

  tags = {
    cluster_name = local.cluster_name
  }

  depends_on = [module.vpc]
}

resource "null_resource" "helm_module_sleep_after_destroy" {
  triggers = {
    sleep_after_destroy = "sleep 200"
  }

  provisioner "local-exec" {
    when = destroy
    command = self.triggers.sleep_after_destroy
  }

  depends_on = [module.eks, module.vpc, helm_release.aws_load_balancer_controller, aws_eip.ingress, local_file.kube_config]
}

module "helm" {
  source = "../helm"

  chart_configs = var.cluster.helm

  charts = {
    "metrics-server" = {
            "values" = <<-EOF
            # Values from terraform EKS module
            EOF
    },
    "external-secrets" = {
      "values" = <<-EOF
      # Values from terraform EKS module
      EOF
    },
    "external-dns" = {
      "values" = <<-EOF
      # Values from terraform EKS module
      provider: aws

      aws:
        region: "${var.cluster.location.region}"
        zoneType: "public"
        #evaluateTargetHealth: "true"

      txtOwnerId: "${local.cluster_name}.${var.cluster.location["region"]}"

      serviceAccount:
        annotations:
          eks.amazonaws.com/role-arn: "${module.iam_assumable_role_admin["external-dns"].iam_role_arn}"
      EOF
    },
    "ingress-nginx" = {
      "values" = <<-EOF
      # Values from terraform EKS module
      controller:
        service:
          loadBalancerIP: ${aws_eip.ingress[0].public_ip}
          annotations:
            service.beta.kubernetes.io/aws-load-balancer-type: external
            #service.beta.kubernetes.io/aws-load-balancer-type: nlb
            service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
            service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
            service.beta.kubernetes.io/aws-load-balancer-eip-allocations: ${join(",", aws_eip.ingress.*.id)}
            service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags: cluster=${local.cluster_name}
      EOF
    },
    "haproxy-ingress" = {
      "values" = <<-EOF
      # Values from terraform EKS module
      controller:
        service:
          annotations:
            service.beta.kubernetes.io/aws-load-balancer-type: external
            #service.beta.kubernetes.io/aws-load-balancer-type: nlb
            service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
            service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
            service.beta.kubernetes.io/aws-load-balancer-eip-allocations: ${join(",", aws_eip.ingress.*.id)}
            service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags: cluster=${local.cluster_name}
        #nodeSelector:
        #  "frontend": "true"
        #tolerations:
        #  - key: "WorkerAttachedToExtLoadBalancer"
        #    operator: "Exists"
        #    effect: "NoSchedule"
      defaultBackend:
        service:
          omitClusterIP: true
      EOF
    },
    "cert-manager" = {
      "values" = <<-EOF
      # Values from terraform EKS module
      EOF
    },
    "kube-prometheus-stack" = {
      "values" = <<-EOF
      # Values from terraform EKS module
      EOF
    },
    "elasticsearch" = {
      "values" = <<-EOF
      # Values from terraform EKS module
      EOF
    },
    "logstash" = {
      "values" = <<-EOF
      # Values from terraform EKS module
      EOF
    },
    "kibana" = {
      "values" = <<-EOF
      # Values from terraform EKS module
      EOF
    },
    "raw-k8s-resources" = {
      "values" = <<-EOF
      # Values from terraform EKS module
      resources:
        - apiVersion: storage.k8s.io/v1
          kind: StorageClass
          metadata:
            name: fast
            #annotations:
            #  "storageclass.kubernetes.io/is-default-class": "true"
          provisioner: ebs.csi.aws.com
          reclaimPolicy: Delete
          volumeBindingMode: WaitForFirstConsumer
        - apiVersion: storage.k8s.io/v1
          kind: StorageClass
          metadata:
            name: standard
          provisioner: kubernetes.io/aws-ebs
          reclaimPolicy: Delete
          parameters:
            type: gp2
        #- apiVersion: storage.k8s.io/v1
        #  kind: StorageClass
        #  metadata:
        #    name: gp2
        #    annotations:
        #      "storageclass.kubernetes.io/is-default-class": "false"
        #  provisioner: kubernetes.io/aws-ebs
        #  reclaimPolicy: Delete
        #  volumeBindingMode: WaitForFirstConsumer
        - apiVersion: snapshot.storage.k8s.io/v1
          kind: VolumeSnapshotClass
          metadata:
            name: ds-snapshot-class
          driver: ebs.csi.aws.com
          deletionPolicy: Delete
      EOF
    },
    "secret-agent" = {
      "values" = <<-EOF
      # Values from terraform GKE module
      EOF
    },
    "ds-operator" = {
      "values" = <<-EOF
      # Values from terraform GKE module
      EOF
    },
    "identity-platform" = {
      "values" = <<-EOF
      # Values from terraform GKE module
      platform:
        ingress:
          hosts:
            - identity-platform.${aws_eip.ingress[0].public_ip}.nip.io
      EOF
    }
  }

  depends_on = [module.eks, module.vpc, module.iam_assumable_role_admin["external-dns"], aws_eip.ingress, local_file.kube_config, helm_release.aws_ebs_csi_driver, helm_release.snapshot_controller, helm_release.aws_load_balancer_controller, helm_release.cluster_autoscaler, null_resource.helm_module_sleep_after_destroy]
}

