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
  database_subnets = ["10.0.12.0/24", "10.0.22.0/24"] #데이터베이스 서브넷

  create_database_subnet_group = true
  create_database_subnet_route_table = true 
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
resource "aws_iam_policy" "ebs_csi_controller" {
  name_prefix = "ebs-csi-controller"
  description = "EKS ebs-csi-controller policy for cluster ${local.name}"
  policy      = file("./addons.json")
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
    aws-ebs-csi-driver = {
      # service_account_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.name}-ebs-csi-controller"
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }

  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["t2.micro", "t3.medium"]

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


################################################################################
# GitHub OIDC Provider
# Note: This is one per AWS account
################################################################################

module "iam_github_oidc_provider" {
  source = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"

  tags = {
    Name = "iam-provider-github-oidc"
    }
}


################################################################################
# GitHub OIDC Role
################################################################################
resource "aws_iam_policy" "ECR_Read_Write" {
  name = "ECR_Read_Write"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid": "GetAuthorizationToken"
        "Action": [
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability",
            "ecr:CompleteLayerUpload",
            "ecr:GetDownloadUrlForLayer",
            "ecr:InitiateLayerUpload",
            "ecr:PutImage",
            "ecr:UploadLayerPart",
            "ecr:GetAuthorizationToken"
        ]
        "Effect"   = "Allow"
        "Resource" = "*"
        # "Resource" = "arn:aws:ecr:ap-northeast-2:${data.aws_caller_identity.current.account_id}:repository/nsus"
      },
    ]
  })

}


module "iam_github_oidc_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"

  name = "iam-role-github-oidc"

  # This should be updated to suit your organization, repository, references/branches, etc.
  subjects = [
    "repo:alli-eunbi/nsus:*"
  ]

  policies = {
    # S3ReadOnly = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
    additional = aws_iam_policy.ECR_Read_Write.arn
    # resource = "arn:aws:ecr:ap-northeast-2:${data.aws_caller_identity.current.account_id}:repository/nsus"
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

# resource "aws_ecr_repository_policy" "nsus_ecr_policy" {
#   repository = aws_ecr_repository.nsus-ecr.name
#   policy     = aws_iam_policy.ECR_Read_Write.policy.json
# }

output "ecr_registry_id" {
  value = aws_ecr_repository.nsus-ecr.registry_id
}

output "ecr_repository_url" {
  value = aws_ecr_repository.nsus-ecr.repository_url
}

################################################################################
# RDS Module
################################################################################
module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${local.name}-default"

  create_db_option_group    = false
  create_db_parameter_group = false

  # All available versions: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.VersionMgmt
  engine               = "mysql"
  engine_version       = "8.0"
  family               = "mysql8.0" # DB parameter group
  major_engine_version = "8.0"      # DB option group
  instance_class       = "db.t4g.micro"

  allocated_storage = 200

  db_name  = "nsus"
  username = "admin"
  port     = 3306


  multi_az               = false
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.security_group.security_group_id]
  create_cloudwatch_log_group     = false
  publicly_accessible = true

  skip_final_snapshot = true
  deletion_protection = false

  performance_insights_enabled          = false
  create_monitoring_role                = false


  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]

  tags = local.tags
}
module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "sg_mysql"
  description = "Complete MySQL example security group"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "MySQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  tags = {
    Name = "sg-mysql"
  }
}