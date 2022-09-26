# iam.tf - IAM policies for the cluster

locals {
  arn_partition = length(regexall("^us-gov-", var.cluster.location.region)) > 0 ? "aws-us-gov" : "aws"

  iam_policies = {
    aws-ebs-csi-driver = {
      service_account_namespace = "kube-system"
      service_account_name      = "ebs-csi-controller-sa"
      policy                   = {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Action": [
              "ec2:CreateSnapshot",
              "ec2:AttachVolume",
              "ec2:DetachVolume",
              "ec2:ModifyVolume",
              "ec2:DescribeAvailabilityZones",
              "ec2:DescribeInstances",
              "ec2:DescribeSnapshots",
              "ec2:DescribeTags",
              "ec2:DescribeVolumes",
              "ec2:DescribeVolumesModifications"
            ],
            "Resource": "*"
          },
          {
            "Effect": "Allow",
            "Action": [
              "ec2:CreateTags"
            ],
            "Resource": [
              "arn:${local.arn_partition}:ec2:*:*:volume/*",
              "arn:${local.arn_partition}:ec2:*:*:snapshot/*"
            ],
            "Condition": {
              "StringEquals": {
                "ec2:CreateAction": [
                  "CreateVolume",
                  "CreateSnapshot"
                ]
              }
            }
          },
          {
            "Effect": "Allow",
            "Action": [
              "ec2:DeleteTags"
            ],
            "Resource": [
              "arn:${local.arn_partition}:ec2:*:*:volume/*",
              "arn:${local.arn_partition}:ec2:*:*:snapshot/*"
            ]
          },
          {
            "Effect": "Allow",
            "Action": [
              "ec2:CreateVolume"
            ],
            "Resource": "*",
            "Condition": {
              "StringLike": {
                "aws:RequestTag/ebs.csi.aws.com/cluster": "true"
              }
            }
          },
          {
            "Effect": "Allow",
            "Action": [
              "ec2:CreateVolume"
            ],
            "Resource": "*",
            "Condition": {
              "StringLike": {
                "aws:RequestTag/CSIVolumeName": "*"
              }
            }
          },
          {
            "Effect": "Allow",
            "Action": [
              "ec2:CreateVolume"
            ],
            "Resource": "*",
            "Condition": {
              "StringLike": {
                "aws:RequestTag/kubernetes.io/cluster/*": "owned"
              }
            }
          },
          {
            "Effect": "Allow",
            "Action": [
              "ec2:DeleteVolume"
            ],
            "Resource": "*",
            "Condition": {
              "StringLike": {
                "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
              }
            }
          },
          {
            "Effect": "Allow",
            "Action": [
              "ec2:DeleteVolume"
            ],
            "Resource": "*",
            "Condition": {
              "StringLike": {
                "ec2:ResourceTag/CSIVolumeName": "*"
              }
            }
          },
          {
            "Effect": "Allow",
            "Action": [
              "ec2:DeleteVolume"
            ],
            "Resource": "*",
            "Condition": {
              "StringLike": {
                "ec2:ResourceTag/kubernetes.io/cluster/*": "owned"
              }
            }
          },
          {
            "Effect": "Allow",
            "Action": [
              "ec2:DeleteSnapshot"
            ],
            "Resource": "*",
            "Condition": {
              "StringLike": {
                "ec2:ResourceTag/CSIVolumeSnapshotName": "*"
              }
            }
          },
          {
            "Effect": "Allow",
            "Action": [
              "ec2:DeleteSnapshot"
            ],
            "Resource": "*",
            "Condition": {
              "StringLike": {
                "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
              }
            }
          }
        ]
      }
    },
    cluster-autoscaler = {
      service_account_namespace = "kube-system"
      service_account_name      = "cluster-autoscaler-aws-cluster-autoscaler"
      policy                    = {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Action": [
              "autoscaling:DescribeAutoScalingGroups",
              "autoscaling:DescribeAutoScalingInstances",
              "autoscaling:DescribeLaunchConfigurations",
              "autoscaling:DescribeTags",
              "ec2:DescribeLaunchTemplateVersions"
            ],
            "Resource": "*"
          },
          {
            "Effect": "Allow",
            "Action": [
              "autoscaling:SetDesiredCapacity",
              "autoscaling:TerminateInstanceInAutoScalingGroup",
              "autoscaling:UpdateAutoScalingGroup"
            ],
            "Resource": "*",
            "Condition": {
              "StringEquals": {
                "autoscaling:ResourceTag/kubernetes.io/cluster/${module.eks.cluster_id}": "owned"
              },
              "StringEquals": {
                "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled": "true"
              }
            }
          }
        ]
      }
    },
    aws-load-balancer-controller = {
      service_account_namespace = "kube-system"
      service_account_name      = "aws-load-balancer-controller"
      policy                    = {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Action": [
              "iam:CreateServiceLinkedRole",
              "ec2:DescribeAccountAttributes",
              "ec2:DescribeAddresses",
              "ec2:DescribeAvailabilityZones",
              "ec2:DescribeInternetGateways",
              "ec2:DescribeVpcs",
              "ec2:DescribeSubnets",
              "ec2:DescribeSecurityGroups",
              "ec2:DescribeInstances",
              "ec2:DescribeNetworkInterfaces",
              "ec2:DescribeTags",
              "ec2:GetCoipPoolUsage",
              "ec2:DescribeCoipPools",
              "elasticloadbalancing:DescribeLoadBalancers",
              "elasticloadbalancing:DescribeLoadBalancerAttributes",
              "elasticloadbalancing:DescribeListeners",
              "elasticloadbalancing:DescribeListenerCertificates",
              "elasticloadbalancing:DescribeSSLPolicies",
              "elasticloadbalancing:DescribeRules",
              "elasticloadbalancing:DescribeTargetGroups",
              "elasticloadbalancing:DescribeTargetGroupAttributes",
              "elasticloadbalancing:DescribeTargetHealth",
              "elasticloadbalancing:DescribeTags"
            ],
            "Resource": "*"
          },
          {
            "Effect": "Allow",
            "Action": [
              "cognito-idp:DescribeUserPoolClient",
              "acm:ListCertificates",
              "acm:DescribeCertificate",
              "iam:ListServerCertificates",
              "iam:GetServerCertificate",
              "waf-regional:GetWebACL",
              "waf-regional:GetWebACLForResource",
              "waf-regional:AssociateWebACL",
              "waf-regional:DisassociateWebACL",
              "wafv2:GetWebACL",
              "wafv2:GetWebACLForResource",
              "wafv2:AssociateWebACL",
              "wafv2:DisassociateWebACL",
              "shield:GetSubscriptionState",
              "shield:DescribeProtection",
              "shield:CreateProtection",
              "shield:DeleteProtection"
            ],
            "Resource": "*"
          },
          {
            "Effect": "Allow",
            "Action": [
              "ec2:AuthorizeSecurityGroupIngress",
              "ec2:RevokeSecurityGroupIngress"
            ],
            "Resource": "*"
          },
          {
            "Effect": "Allow",
            "Action": [
              "ec2:CreateSecurityGroup"
            ],
            "Resource": "*"
          },
          {
            "Effect": "Allow",
            "Action": [
              "ec2:CreateTags"
            ],
            "Resource": "arn:${local.arn_partition}:ec2:*:*:security-group/*",
            "Condition": {
              "StringEquals": {
                "ec2:CreateAction": "CreateSecurityGroup"
              },
              "Null": {
                "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
              }
            }
          },
          {
            "Effect": "Allow",
            "Action": [
              "ec2:CreateTags",
              "ec2:DeleteTags"
            ],
            "Resource": "arn:${local.arn_partition}:ec2:*:*:security-group/*",
            "Condition": {
              "Null": {
                "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
              }
            }
          },
          {
            "Effect": "Allow",
            "Action": [
              "ec2:AuthorizeSecurityGroupIngress",
              "ec2:RevokeSecurityGroupIngress",
              "ec2:DeleteSecurityGroup"
            ],
            "Resource": "*",
            "Condition": {
              "Null": {
                "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
              }
            }
          },
          {
            "Effect": "Allow",
            "Action": [
              "elasticloadbalancing:CreateLoadBalancer",
              "elasticloadbalancing:CreateTargetGroup"
            ],
            "Resource": "*",
            "Condition": {
              "Null": {
                "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
              }
            }
          },
          {
            "Effect": "Allow",
            "Action": [
              "elasticloadbalancing:CreateListener",
              "elasticloadbalancing:DeleteListener",
              "elasticloadbalancing:CreateRule",
              "elasticloadbalancing:DeleteRule"
            ],
            "Resource": "*"
          },
          {
            "Effect": "Allow",
            "Action": [
              "elasticloadbalancing:AddTags",
              "elasticloadbalancing:RemoveTags"
            ],
            "Resource": [
              "arn:${local.arn_partition}:elasticloadbalancing:*:*:targetgroup/*/*",
              "arn:${local.arn_partition}:elasticloadbalancing:*:*:loadbalancer/net/*/*",
              "arn:${local.arn_partition}:elasticloadbalancing:*:*:loadbalancer/app/*/*"
            ],
            "Condition": {
              "Null": {
                "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
              }
            }
          },
          {
            "Effect": "Allow",
            "Action": [
              "elasticloadbalancing:AddTags",
              "elasticloadbalancing:RemoveTags"
            ],
            "Resource": [
              "arn:${local.arn_partition}:elasticloadbalancing:*:*:listener/net/*/*/*",
              "arn:${local.arn_partition}:elasticloadbalancing:*:*:listener/app/*/*/*",
              "arn:${local.arn_partition}:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
              "arn:${local.arn_partition}:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
            ]
          },
          {
            "Effect": "Allow",
            "Action": [
              "elasticloadbalancing:ModifyLoadBalancerAttributes",
              "elasticloadbalancing:SetIpAddressType",
              "elasticloadbalancing:SetSecurityGroups",
              "elasticloadbalancing:SetSubnets",
              "elasticloadbalancing:DeleteLoadBalancer",
              "elasticloadbalancing:ModifyTargetGroup",
              "elasticloadbalancing:ModifyTargetGroupAttributes",
              "elasticloadbalancing:DeleteTargetGroup"
            ],
            "Resource": "*",
            "Condition": {
              "Null": {
                "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
              }
            }
          },
          {
            "Effect": "Allow",
            "Action": [
              "elasticloadbalancing:RegisterTargets",
              "elasticloadbalancing:DeregisterTargets"
            ],
            "Resource": "arn:${local.arn_partition}:elasticloadbalancing:*:*:targetgroup/*/*"
          },
          {
            "Effect": "Allow",
            "Action": [
              "elasticloadbalancing:SetWebAcl",
              "elasticloadbalancing:ModifyListener",
              "elasticloadbalancing:AddListenerCertificates",
              "elasticloadbalancing:RemoveListenerCertificates",
              "elasticloadbalancing:ModifyRule"
            ],
            "Resource": "*"
          }
        ]
      }
    },
    external-dns = {
      service_account_namespace = "external-dns"
      service_account_name      = "external-dns"
      policy                    = {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Action": [
              "route53:ChangeResourceRecordSets"
            ],
            "Resource": [
              "arn:${local.arn_partition}:route53:::hostedzone/*"
            ]
          },
          {
            "Effect": "Allow",
            "Action": [
              "route53:ListHostedZones",
              "route53:ListResourceRecordSets"
            ],
            "Resource": [
              "*"
            ]
          }
        ]
      }
    }
  }
}

resource "aws_iam_policy" "policy" {
  for_each    = local.iam_policies

  name_prefix = "${local.cluster_name}-${each.key}"
  description = "EKS ${each.key} policy for cluster ${module.eks.cluster_id}"
  policy      = jsonencode(each.value["policy"])
}

module "iam_assumable_role_admin" {
  for_each         = local.iam_policies

  source           = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version          = "~> 5.4"

  create_role      = true
  role_name_prefix = substr("${local.cluster_name}-${each.key}", 0, 32)
  provider_url     = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns = [aws_iam_policy.policy[each.key].arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${each.value["service_account_namespace"]}:${each.value["service_account_name"]}"]
}

