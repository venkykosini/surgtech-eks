output "stack_name" {
  value = local.name
}

output "account_id" {
  value = local.account_id
}

output "aws_region" {
  value = var.aws_region
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "frontend_repository_url" {
  value = module.ecr.frontend_repository_url
}

output "backend_repository_url" {
  value = module.ecr.backend_repository_url
}

output "tags" {
  value = local.tags
}
