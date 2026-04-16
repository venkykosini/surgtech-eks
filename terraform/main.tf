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
  }, var.tags)
}

resource "aws_s3_bucket" "artifacts" {
  count = var.enable_cicd ? 1 : 0

  bucket        = "${local.name}-artifacts-${local.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  count = var.enable_cicd ? 1 : 0

  bucket = aws_s3_bucket.artifacts[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "artifacts" {
  count = var.enable_cicd ? 1 : 0

  bucket = aws_s3_bucket.artifacts[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  count = var.enable_cicd ? 1 : 0

  bucket = aws_s3_bucket.artifacts[0].id

  rule {
    id     = "expire-old-artifacts"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  count = var.enable_cicd ? 1 : 0

  bucket = aws_s3_bucket.artifacts[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_iam_role" "codebuild_role" {
  count = var.enable_cicd ? 1 : 0

  name = "${local.name}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  count = var.enable_cicd ? 1 : 0

  name = "${local.name}-codebuild-policy"
  role = aws_iam_role.codebuild_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.artifacts[0].arn,
          "${aws_s3_bucket.artifacts[0].arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "codepipeline_role" {
  count = var.enable_cicd ? 1 : 0

  name = "${local.name}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  count = var.enable_cicd ? 1 : 0

  name = "${local.name}-codepipeline-policy"
  role = aws_iam_role.codepipeline_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.artifacts[0].arn,
          "${aws_s3_bucket.artifacts[0].arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = aws_codebuild_project.deploy[0].arn
      },
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = var.codestar_connection_arn
      }
    ]
  })
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name}-vpc"
  cidr = "10.10.0.0/16"

  azs             = local.azs
  public_subnets  = ["10.10.1.0/24", "10.10.2.0/24"]
  private_subnets = []
  map_public_ip_on_launch = true

  enable_nat_gateway = false
  single_nat_gateway = false

  public_subnet_tags = {
    "kubernetes.io/role/elb"               = 1
    "kubernetes.io/cluster/${local.name}" = "shared"
  }
}

module "ecr" {
  source = "./modules/ecr"

  project_name = local.name
  tags         = local.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                   = local.name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true
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

  access_entries = {
    for k, v in var.enable_cicd ? { codebuild = true } : {} :
    k => {
      principal_arn = aws_iam_role.codebuild_role[0].arn

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}

resource "aws_codebuild_project" "deploy" {
  count = var.enable_cicd ? 1 : 0

  name         = "${local.name}-build"
  service_role = aws_iam_role.codebuild_role[0].arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.account_id
    }

    environment_variable {
      name  = "EKS_CLUSTER_NAME"
      value = module.eks.cluster_name
    }

    environment_variable {
      name  = "FRONTEND_REPOSITORY_URI"
      value = module.ecr.frontend_repository_url
    }

    environment_variable {
      name  = "BACKEND_REPOSITORY_URI"
      value = module.ecr.backend_repository_url
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "cicd/buildspec.yml"
  }
}

resource "aws_codepipeline" "this" {
  count = var.enable_cicd ? 1 : 0

  name     = "${local.name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role[0].arn

  artifact_store {
    location = aws_s3_bucket.artifacts[0].bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "GitHubSource"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo}"
        BranchName       = var.github_branch
      }
    }
  }

  stage {
    name = "BuildAndDeploy"

    action {
      name             = "BuildAndDeploy"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.deploy[0].name
      }
    }
  }
}
