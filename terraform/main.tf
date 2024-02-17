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
  source  = "terraform-aws-modules/vpc/aws//examples/complete"
  version = "5.5.2"

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
  cluster_ip_family          = "ipv6"
  create_cni_ipv6_iam_policy = true

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
    aws-ebs-csi-driver = {
      service_account_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.name}-ebs-csi-controller"
    }

  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["t2.micro"]

    min_size = 2
    max_size = 3
    desired_size = 2
  }

  eks_managed_node_groups = {
    # Default node group - as provided by AWS EKS
    default_node_group = {
      disk_size = 30

      # Remote access cannot be specified with a launch template
      remote_access = {
        ec2_ssh_key               = module.key_pair.key_pair_name
        source_security_group_ids = [aws_security_group.remote_access.id]
      }
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
  }

  tags = local.tags
}

