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

output "pipeline_name" {
  value = var.enable_cicd ? aws_codepipeline.this[0].name : null
}

output "artifact_bucket_name" {
  value = var.enable_cicd ? aws_s3_bucket.artifacts[0].bucket : null
}
