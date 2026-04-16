provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

locals {
  name       = "${var.project_name}-${var.environment}"
  account_id = data.aws_caller_identity.current.account_id
  azs        = slice(data.aws_availability_zones.available.names, 0, 2)
  tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Stack       = "base"
  }, var.tags)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name}-vpc"
  cidr = "10.10.0.0/16"

  azs                  = local.azs
  public_subnets       = ["10.10.1.0/24", "10.10.2.0/24"]
  private_subnets      = []
  map_public_ip_on_launch = true

  enable_nat_gateway = false
  single_nat_gateway = false

  public_subnet_tags = {
    "kubernetes.io/role/elb"              = 1
    "kubernetes.io/cluster/${local.name}" = "shared"
  }
}

module "ecr" {
  source = "../modules/ecr"

  project_name = local.name
  tags         = local.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                    = local.name
  cluster_version                 = var.cluster_version
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false
  cluster_enabled_log_types       = []
  create_cloudwatch_log_group     = false
  cluster_encryption_config       = {}
  create_kms_key                  = false

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  enable_irsa = true
  tags        = local.tags

  eks_managed_node_groups = {
    default = {
      instance_types = var.node_instance_types
      capacity_type  = var.node_capacity_type
      desired_size   = var.desired_size
      min_size       = var.min_size
      max_size       = var.max_size

      subnet_ids = module.vpc.public_subnets
      ami_type   = "AL2_x86_64"
    }
  }
}
