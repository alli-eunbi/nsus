data "aws_caller_identity" "current" {}


provider "aws" {
  region = local.region
}

# data "aws_caller_identity" "current" {}

locals {
  name    = "nsus-cluster"
#   todo: cluster verison 확인
#   cluster_version = "1.27"

  region  = "ap-northeast-2"
  vpc_cidr = "10.0.0.0/16"
  
  # cidr 10.0.0.0/24는 aws 자체적으로 예약된 ip 주소가 이미 5개 정도 존재하므로 10.0.1.0 으로 시작되도록 설정
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
  
  azs = ["ap-northeast-2a", "ap-northeast-2c"]

  tags = {
    Name    = local.name
    }
}


################################################################################
# VPC Module
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name = local.name
  cidr = local.vpc_cidr

  azs                 = local.azs
  private_subnets     = local.private_subnets
  public_subnets      = local.public_subnets

  private_subnet_names = ["private-subnet-a", "private-subnet-c"]
  public_subnet_names = ["public-subnet-a", "public-subnet-c"]
  # 실제 운영 서버라면 컨트롤 플레인 접근을 vpc 내부로만 진행하도록 intrasubnet을 활용했겠지만, 과제이기 때문에 생략.
#   intra_subnet_names       = []

  manage_default_network_acl    = false
  manage_default_route_table    = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true

  tags = local.tags
}

################################################################################
# CSI IAM ROLE
################################################################################
module "ebs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "${local.name}-ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}
# module "ebs_csi_controller_role" {
#   source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
#   create_role                   = true
#   role_name                     = "${local.name}-ebs-csi-controller"
#   provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
#   role_policy_arns              = [aws_iam_policy.ebs_csi_controller.arn]
#   oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:$ebs-csi-controller-sa"]
# }

# resource "aws_iam_policy" "ebs_csi_controller" {
#   name_prefix = "ebs-csi-controller"
#   description = "EKS ebs-csi-controller policy for cluster ${local.name}"
#   policy      = file("${path.module}/policies/ebs_csi_controller_iam_policy.json")
# }


################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.2.1"

  cluster_name                   = local.name
#   cluster_version                = local.cluster_version
# 실제 운영 환경이라면 cluter_endpoint_public_access를 false 처리하고 vpn 내부 접근으로 변경할것
  cluster_endpoint_public_access = true

  # IPV6
  # cluster_ip_family          = "ipv6"
  # create_cni_ipv6_iam_policy = true

  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
    }
    # aws-ebs-csi-driver = {
    #   # service_account_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.name}-ebs-csi-controller"
    #   service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    # }

  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["t2.micro"]

  }

  eks_managed_node_groups = {
    nsus_node_group = {
      min_size = 2
      max_size = 3
      desired_size = 2
      disk_size = 20

      # Remote access cannot be specified with a launch template
      # ISMS 보안 정책 위배
      # remote_access = {
      #   ec2_ssh_key               = module.key_pair.key_pair_name
      #   source_security_group_ids = [aws_security_group.remote_access.id]
      # }
    }
    tags = local.tags
  }

  # create_iam_role          = true
  # iam_role_name            = "iam-managed-node-group"
  # iam_role_use_name_prefix = false
  # iam_role_description     = "EKS managed node group complete example role"
  # iam_role_tags = {
  #   Purpose = "Protector of the kubelet"
  # }
  # iam_role_additional_policies = {
  #   AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  #   additional                         = aws_iam_policy.node_additional.arn
  # }
      
}
resource aws_eks_access_entry nsus_cluster {
  cluster_name = local.name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/nsus"
  type = "STANDARD"
}

  
  # 나중에 운영에 가깝게 만들고 싶을때를 위해 잠시 주석 처리
#     # Complete
#     complete = {
#       name            = "complete-eks-mng"
#       use_name_prefix = true

#       subnet_ids = module.vpc.private_subnets

#       min_size     = 1
#       max_size     = 7
#       desired_size = 1

#       ami_id                     = data.aws_ami.eks_default.image_id
#       enable_bootstrap_user_data = true

#       pre_bootstrap_user_data = <<-EOT
#         export FOO=bar
#       EOT

#       post_bootstrap_user_data = <<-EOT
#         echo "you are free little kubelet!"
#       EOT

#       capacity_type        = "SPOT"
#       force_update_version = true
#       instance_types       = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
#       labels = {
#         GithubRepo = "terraform-aws-eks"
#         GithubOrg  = "terraform-aws-modules"
#       }

#       taints = [
#         {
#           key    = "dedicated"
#           value  = "gpuGroup"
#           effect = "NO_SCHEDULE"
#         }
#       ]

#       update_config = {
#         max_unavailable_percentage = 33 # or set `max_unavailable`
#       }

#       description = "EKS managed node group example launch template"

#       ebs_optimized           = true
#       disable_api_termination = false
#       enable_monitoring       = true

#       block_device_mappings = {
#         xvda = {
#           device_name = "/dev/xvda"
#           ebs = {
#             volume_size           = 75
#             volume_type           = "gp3"
#             iops                  = 3000
#             throughput            = 150
#             encrypted             = true
#             kms_key_id            = module.ebs_kms_key.key_arn
#             delete_on_termination = true
#           }
#         }
#       }

#       metadata_options = {
#         http_endpoint               = "enabled"
#         http_tokens                 = "required"
#         http_put_response_hop_limit = 2
#         instance_metadata_tags      = "disabled"
#       }

#       create_iam_role          = true
#       iam_role_name            = "eks-managed-node-group-complete-example"
#       iam_role_use_name_prefix = false
#       iam_role_description     = "EKS managed node group complete example role"
#       iam_role_tags = {
#         Purpose = "Protector of the kubelet"
#       }
#       iam_role_additional_policies = {
#         AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#         additional                         = aws_iam_policy.node_additional.arn
#       }

#       tags = {
#         ExtraTag = "EKS managed node group complete example"
#       }
#     }
#   }

#   access_entries = {
#     # One access entry with a policy associated
#     ex-single = {
#       kubernetes_groups = []
#       principal_arn     = aws_iam_role.this["single"].arn

#       policy_associations = {
#         single = {
#           policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
#           access_scope = {
#             namespaces = ["default"]
#             type       = "namespace"
#           }
#         }
#       }
#     }

#     # Example of adding multiple policies to a single access entry
#     ex-multiple = {
#       kubernetes_groups = []
#       principal_arn     = aws_iam_role.this["multiple"].arn

#       policy_associations = {
#         ex-one = {
#           policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
#           access_scope = {
#             namespaces = ["default"]
#             type       = "namespace"
#           }
#         }
#         ex-two = {
#           policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
#           access_scope = {
#             type = "cluster"
#           }
#         }
#       }
#     }


# ################################################################################
# # Helm Chart Module
# ################################################################################

# data "aws_eks_cluster" "nsus_cluster" {
#   name = local.name
# }

# data "aws_eks_cluster_auth" "nsus_auth" {
#   name = local.name
# }
# provider "helm" {
#   kubernetes {
#     host  = data.aws_eks_cluster.nsus_cluster.endpoint
#     token = data.aws_eks_cluster_auth.nsus_auth.token
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.nsus_cluster.certificate_authority[0].data)
#   }
# }

# resource "helm_release" "metrics_server" {
#   namespace        = "kube-system"
#   name             = "metrics-server"
#   chart            = "metrics-server"
#   version          = "3.8.2"
#   repository       = "https://kubernetes-sigs.github.io/metrics-server/"
#   create_namespace = true
  
#   set {
#     name  = "replicas"
#     value = 1
#   }
# }


################################################################################
# GitHub OIDC Provider
# Note: This is one per AWS account
################################################################################

module "iam_github_oidc_provider" {
  source = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"

  # tags = {
  #   Name = "iam-provider-github-oidc"
  #   }
}

# module "iam_github_oidc_provider_disabled" {
#   source = "terraform-aws-modules/iam/aws//examples/iam-github-oidc"

#   create = false
# }


################################################################################
# GitHub OIDC Role
################################################################################
resource "aws_iam_policy" "ECR_Read_Write" {
  name = "ECR_Read_Write"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Action": [
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability",
            "ecr:CompleteLayerUpload",
            "ecr:GetDownloadUrlForLayer",
            "ecr:InitiateLayerUpload",
            "ecr:PutImage",
            "ecr:UploadLayerPart"
        ]
        Effect   = "Allow"
      },
    ]
  })

}
module "iam_github_oidc_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"

  name = "iam-role-github-oidc"

  # This should be updated to suit your organization, repository, references/branches, etc.
  subjects = [
    "https://github.com/alli-eunbi/nsus"
  ]

  policies = {
    additional = aws_iam_policy.ECR_Read_Write.arn
    ECRAccess = "arn:aws:iam::aws:policy/AmazonECRAccess"
  }

  tags = {
    name = "iam-role-github-oidc"
  }
}

# module "iam_github_oidc_role_disabled" {
#   source = "terraform-aws-modules/iam/aws//examples/iam-github-oidc"

#   create = false
# }



################################################################################
# ECR
################################################################################
resource "aws_ecr_repository" "nsus-ecr" {
  name                 = "nsus"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}
 

output "ecr_registry_id" {
  value = aws_ecr_repository.nsus-ecr.registry_id
}

output "ecr_repository_url" {
  value = aws_ecr_repository.nsus-ecr.repository_url
}