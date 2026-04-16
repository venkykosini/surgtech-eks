variable "aws_region" {
  description = "AWS region for CI/CD resources."
  type        = string
  default     = "ap-south-1"
}

variable "github_owner" {
  description = "GitHub user or organization."
  type        = string
  default     = "venkykosini"
}

variable "github_repo" {
  description = "GitHub repository name."
  type        = string
  default     = "surgtech-eks"
}

variable "github_branch" {
  description = "GitHub branch that triggers CI/CD."
  type        = string
  default     = "main"
}

variable "codestar_connection_arn" {
  description = "AWS CodeStar connection ARN for GitHub."
  type        = string

  validation {
    condition     = trimspace(var.codestar_connection_arn) != ""
    error_message = "codestar_connection_arn must not be empty."
  }
}

variable "base_state_path" {
  description = "Path to the base stack state file."
  type        = string
  default     = "../base/terraform.tfstate"
}
