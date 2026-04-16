output "pipeline_name" {
  value = aws_codepipeline.this.name
}

output "artifact_bucket_name" {
  value = aws_s3_bucket.artifacts.bucket
}

output "codebuild_role_arn" {
  value = aws_iam_role.codebuild_role.arn
}
