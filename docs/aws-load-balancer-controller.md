# AWS Load Balancer Controller

The ingress manifest uses the AWS Load Balancer Controller.

## Why it is needed

Without it, the `Ingress` resource will not create an AWS Application Load Balancer.

## Basic install outline

1. Create the IAM role for service account using the cluster OIDC provider
2. Install the controller with Helm
3. Ensure your public subnets are tagged for ELB

The Terraform in this repo already tags the public subnets for ELB.

Refer to AWS documentation for the exact controller installation steps for your region and cluster version.
