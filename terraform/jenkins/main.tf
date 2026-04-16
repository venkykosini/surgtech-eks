provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

data "terraform_remote_state" "base" {
  backend = "local"

  config = {
    path = var.base_state_path
  }
}

data "aws_eks_cluster" "this" {
  name = data.terraform_remote_state.base.outputs.cluster_name
}

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  stack_name           = data.terraform_remote_state.base.outputs.stack_name
  cluster_name         = data.terraform_remote_state.base.outputs.cluster_name
  frontend_repository  = data.terraform_remote_state.base.outputs.frontend_repository_url
  backend_repository   = data.terraform_remote_state.base.outputs.backend_repository_url
  account_id           = data.terraform_remote_state.base.outputs.account_id
  repository_clone_url = "https://github.com/${var.github_owner}/${var.github_repo}.git"
  subnet_id            = tolist(data.aws_eks_cluster.this.vpc_config[0].subnet_ids)[0]
  tags = merge(
    data.terraform_remote_state.base.outputs.tags,
    { Stack = "jenkins" }
  )
}

resource "random_password" "jenkins_admin" {
  length           = 20
  special          = true
  override_special = "!@#%^*-_=+"
}

resource "aws_security_group" "jenkins" {
  name        = "${local.stack_name}-jenkins-sg"
  description = "Allow Jenkins web access"
  vpc_id      = data.aws_eks_cluster.this.vpc_config[0].vpc_id

  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.jenkins_ingress_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "jenkins" {
  name = "${local.stack_name}-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "jenkins" {
  name = "${local.stack_name}-jenkins-policy"
  role = aws_iam_role.jenkins.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
      }
    ]
  })
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "${local.stack_name}-jenkins-profile"
  role = aws_iam_role.jenkins.name
}

resource "aws_eks_access_entry" "jenkins" {
  cluster_name  = local.cluster_name
  principal_arn = aws_iam_role.jenkins.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "jenkins_admin" {
  cluster_name  = local.cluster_name
  principal_arn = aws_iam_role.jenkins.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

resource "aws_instance" "jenkins" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = var.instance_type
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  iam_instance_profile        = aws_iam_instance_profile.jenkins.name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user-data.sh.tftpl", {
    aws_region          = var.aws_region
    cluster_name        = local.cluster_name
    kubectl_version     = var.kubectl_version
    frontend_repository = local.frontend_repository
    backend_repository  = local.backend_repository
    github_repo_url     = local.repository_clone_url
    github_branch       = var.github_branch
    jenkins_admin_user  = var.jenkins_admin_username
    jenkins_admin_pass  = random_password.jenkins_admin.result
    jenkins_job_name    = var.jenkins_job_name
  })

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

resource "aws_eip" "jenkins" {
  domain = "vpc"
}

resource "aws_eip_association" "jenkins" {
  instance_id   = aws_instance.jenkins.id
  allocation_id = aws_eip.jenkins.id
}
