# surgtech-eks

Low-cost Amazon EKS starter project with:

- A simple frontend that says "Hello Venky, this is the EKS front end" with lightweight graphics
- A small backend API
- Kubernetes manifests for deployments, services, config, namespace, and ingress
- Terraform for EKS, ECR, and CI/CD
- AWS CodeBuild and CodePipeline wired for a GitHub repository

## Project Structure

- `frontend/` static site served by Nginx
- `backend/` Node.js API
- `k8s/` Kubernetes manifests and templates
- `terraform/` infrastructure as code
- `cicd/` build and deploy helpers
- `docs/` setup notes

## Low-Cost Design

This setup is tuned to keep costs lower, but EKS is never free:

- One small managed node group by default
- Single replica for frontend and backend
- Shared ALB ingress for both apps
- Separate ECR repos for frontend and backend
- Optional scale settings controlled from Terraform variables

## What You Need Before Apply

1. AWS account and AWS CLI credentials
2. Terraform installed
3. Docker installed for local image testing if needed
4. A GitHub repo connected to AWS CodeStar Connections

## Quick Start

1. Open `terraform/terraform.tfvars.example`
2. Copy it to `terraform/terraform.tfvars`
3. Fill in your AWS values, GitHub repo details, and CodeStar connection ARN
4. Set `enable_cicd = true` only when you are ready to create CodeBuild and CodePipeline
5. Run:

```powershell
cd terraform
terraform init
terraform plan
terraform apply
```

6. Install the AWS Load Balancer Controller in the cluster
7. Push this project to your GitHub repo
8. If CI/CD is enabled, CodePipeline will build and deploy to EKS

## Faster Terraform Layout

For faster plans going forward, use the split stacks under `terraform/base` and `terraform/cicd`:

1. Copy `terraform/base/terraform.tfvars.example` to `terraform/base/terraform.tfvars`
2. Run Terraform in `terraform/base` for the VPC, EKS cluster, and ECR repositories
3. Copy `terraform/cicd/terraform.tfvars.example` to `terraform/cicd/terraform.tfvars`
4. Run Terraform in `terraform/cicd` only when you want the pipeline resources

This keeps everyday infrastructure work out of the slower CI/CD graph.

If you want a single entry point for the split layout, use:

```powershell
cd terraform
.\plan-all.ps1
# or
.\apply-all.ps1
```

## Deploy Flow

1. GitHub push triggers CodePipeline
2. CodeBuild builds frontend and backend Docker images
3. CodeBuild pushes images to ECR
4. CodeBuild renders `k8s/all.yml` with the new image tags
5. CodeBuild deploys the rendered manifest to EKS

## Kubernetes Files Included

- `k8s/base/namespace.yml`
- `k8s/base/configmap.yml`
- `k8s/frontend/deployment.yml`
- `k8s/frontend/service.yml`
- `k8s/backend/deployment.yml`
- `k8s/backend/service.yml`
- `k8s/base/ingress.yml`
- `k8s/all.yml`

## Notes

- The ingress uses AWS Load Balancer Controller annotations. Install the controller after the cluster is created.
- If you want the absolute cheapest path, ECS or EC2 would be cheaper than EKS. This repo keeps EKS as small as possible while staying production-shaped.
- Keep `terraform/terraform.tfvars` local because it can contain account-specific or sensitive values.
