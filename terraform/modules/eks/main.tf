# main.tf - cluster module

module "common" {
  source = "../common"

  forgerock = var.forgerock
  cluster   = var.cluster
}

resource "random_id" "cluster" {
  byte_length = 2
}

locals {
  cluster_name = replace(var.cluster.meta.cluster_name, "<id>", random_id.cluster.hex)
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_availability_zones" "available" {
  filter {
    name   = var.cluster.location["zones"] != null ? "zone-name" : "region-name"
    values = var.cluster.location["zones"] != null ? var.cluster.location["zones"] : [var.cluster.location["region"]]
  }
}

# Force update to data.aws_availability_zones.available with:
# terraform apply -target=module.<cluster_XX>.null_resource.aws_availability_zones_available
resource "null_resource" "aws_availability_zones_available" {
  triggers = {
    names = join(",", data.aws_availability_zones.available.names)
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 3.18"
  #create_vpc = true

  name = "${local.cluster_name}-vpc"
  cidr = "10.0.0.0/16"
  azs = data.aws_availability_zones.available.names
  public_subnets = length(data.aws_availability_zones.available.names) > 2 ? ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19", "10.0.96.0/19"] : ["10.0.0.0/18", "10.0.64.0/18"]
  private_subnets = length(data.aws_availability_zones.available.names) > 2 ? ["10.0.128.0/19", "10.0.160.0/19", "10.0.192.0/19", "10.0.224.0/19"] : ["10.0.128.0/18", "10.0.192.0/18"]
  enable_dns_hostnames = true
  enable_dns_support = true
  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

data "aws_ami" "eks_amd64" {
  filter {
    name = "name"
    values = ["amazon-eks-node-${var.cluster.meta.kubernetes_version}-v*"]
  }
  most_recent = true
  owners = ["amazon"]
}

data "aws_ami" "eks_arm64" {
  filter {
    name = "name"
    values = ["amazon-eks-arm64-node-${var.cluster.meta.kubernetes_version}-*"]
  }
  most_recent = true
  owners = ["amazon"]
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 19.5"

  prefix_separator = ""
  cluster_name = local.cluster_name
  cluster_security_group_name = local.cluster_name
  cluster_security_group_description = "EKS cluster security group."
  iam_role_name = local.cluster_name

  cluster_version = var.cluster.meta.kubernetes_version

  vpc_id = module.vpc.vpc_id
  enable_irsa = true
  subnet_ids = module.vpc.private_subnets

  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true

  #cluster_addons = {
  #  coredns = {
  #    resolve_conflicts = "OVERWRITE"
  #  }
  #  kube-proxy = {}
  #  vpc-cni = {
  #    resolve_conflicts = "OVERWRITE"
  #  }
  #  aws-ebs-csi-driver = {
  #    resolve_conflicts = "OVERWRITE"
  #  }
  #}

  cluster_security_group_additional_rules = {
    egress_internet_all = {
      description = "Allow cluster egress access to the Internet."
      protocol = "-1"
      from_port = 0
      to_port = 65535
      type = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress_nodes_all = {
      description = "Allow cluster ingress access from the nodes."
      protocol = "-1"
      from_port = 0
      to_port = 65535
      type = "ingress"
      source_node_security_group = true
    }

  }

  node_security_group_additional_rules = {
    egress_internet_all = {
      description = "Allow nodes all egress to the Internet."
      protocol = "-1"
      from_port = 0
      to_port = 65535
      type = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress_cluster_all = {
      description = "Allow workers pods to receive communication from the cluster control plane."
        protocol = "-1"
        from_port = 0
        to_port = 65535
        type = "ingress"
        source_cluster_security_group = true
      }
      egress_self_all = {
        description = "Allow nodes to communicate with each other."
        protocol = "-1"
        from_port = 0
        to_port = 65535
        type = "egress"
        self = true
      }
      ingress_self_all = {
        description = "Allow nodes to communicate with each other."
        protocol = "-1"
        from_port = 0
        to_port = 65535
        type = "ingress"
        self = true
      }
  }

  self_managed_node_group_defaults = {
    create_security_group = false
    #iam_role_additional_policies = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  }

  self_managed_node_groups = {
    default_node_pool = {
      name = "default-node-pool"
      #create_launch_template = false
      #launch_template_id = aws_launch_template.compute[pool_name].id
      instance_type = var.cluster.node_pool.type
      ami_id = lookup(var.cluster.meta, "arch", "") == "arm64" ? data.aws_ami.eks_arm64.id : data.aws_ami.eks_amd64.id
      desired_size = var.cluster.node_pool.initial_count
      min_size = var.cluster.node_pool.min_count
      max_size = var.cluster.node_pool.max_count
      key_name = ""
      #instance_refresh = {
      #  strategy = "Rolling"
      #  preferences = {
      #    checkpoint_delay       = 600
      #    checkpoint_percentages = [35, 70, 100]
      #    instance_warmup        = 300
      #    min_healthy_percentage = 50
      #  }
      #}
      #network_interfaces = [
      #  {
      #    device_index = 0
      #    associate_public_ip_address = true
      #  }
      #]
      tags = merge(
        module.common.asset_labels,
        {
          "k8s.io/cluster-autoscaler/enabled" = "true"
          "k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned"
          "k8s.io/cluster-autoscaler/node-template/label/node.kubernetes.io/instance-type" = var.cluster.node_pool.type
          "k8s.io/cluster-autoscaler/node-template/label/kubernetes.io/arch" = lookup(var.cluster.meta, "arch", null) == "arm64" ? "arm64" : "amd64"
        }
      )
    },
  }

  tags = merge(
    module.common.asset_labels,
    {
      cluster_name = local.cluster_name
    }
  )
}

