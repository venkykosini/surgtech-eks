# Jenkins Setup

This repo includes a Jenkins-based CI/CD path that runs alongside AWS CodePipeline.

## What Gets Created

- One small EC2 instance for Jenkins
- Public Jenkins UI on port `8080`
- Elastic IP for a stable webhook URL
- IAM instance profile with ECR push and EKS access
- A pre-created Jenkins pipeline job that reads `Jenkinsfile`

## Terraform Stack

Use the separate stack under `terraform/jenkins`.

```powershell
cd terraform/jenkins
terraform init
terraform apply
```

## Outputs

After apply, collect:

- `jenkins_url`
- `jenkins_webhook_url`
- `jenkins_admin_username`
- `jenkins_admin_password`

## GitHub Webhook

In GitHub repo settings:

1. Open `Settings > Webhooks`
2. Add a webhook
3. Payload URL: the `jenkins_webhook_url` output
4. Content type: `application/json`
5. Event: `Just the push event`

## Jenkins Job

The EC2 bootstrap creates a pipeline job named `surgtech-eks-pipeline`.

It uses:

- `Jenkinsfile`
- GitHub push trigger
- Docker builds for frontend and backend
- ECR push
- `kubectl apply` deployment to EKS
