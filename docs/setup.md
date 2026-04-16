# Setup Notes

## 1. Push This Code

Push the contents of this folder to:

- `https://github.com/venkykosini/surgtech-eks.git`

## 2. Create CodeStar Connection

In AWS:

1. Open Developer Tools
2. Create a CodeStar connection to GitHub
3. Copy the connection ARN

## 3. Install AWS Load Balancer Controller

This ingress setup expects the AWS Load Balancer Controller in the EKS cluster.

## 4. Deploy Terraform

From `terraform/`:

```powershell
terraform init
terraform apply
```

If you want AWS CodeBuild and CodePipeline created too, set `enable_cicd = true` in `terraform.tfvars` before you apply.

For a faster split workflow, use:

```powershell
cd terraform/base
terraform init
terraform apply

cd ../cicd
terraform init
terraform apply
```

Apply `terraform/cicd` only after `terraform/base` has already created the cluster and ECR repositories.

## 5. First Pipeline Run

After Terraform creates the pipeline, push a commit to GitHub. The pipeline will:

- build both containers
- push them to ECR
- render `k8s/all.yml` with the image tags
- deploy to EKS
