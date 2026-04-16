variable "aws_region" {
  description = "AWS region for Jenkins resources."
  type        = string
  default     = "ap-south-1"
}

variable "base_state_path" {
  description = "Path to the base stack state file."
  type        = string
  default     = "../base/terraform.tfstate"
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins."
  type        = string
  default     = "t3.small"
}

variable "root_volume_size" {
  description = "Root volume size in GiB."
  type        = number
  default     = 24
}

variable "jenkins_admin_username" {
  description = "Bootstrap Jenkins admin username."
  type        = string
  default     = "admin"
}

variable "jenkins_job_name" {
  description = "Name of the Jenkins pipeline job to create automatically."
  type        = string
  default     = "surgtech-eks-pipeline"
}

variable "github_owner" {
  description = "GitHub owner for the repository Jenkins should build."
  type        = string
  default     = "venkykosini"
}

variable "github_repo" {
  description = "GitHub repository name Jenkins should build."
  type        = string
  default     = "surgtech-eks"
}

variable "github_branch" {
  description = "GitHub branch Jenkins should build."
  type        = string
  default     = "main"
}

variable "jenkins_ingress_cidrs" {
  description = "CIDR blocks allowed to access the Jenkins web UI."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "kubectl_version" {
  description = "Kubectl version installed on the Jenkins host."
  type        = string
  default     = "v1.30.0"
}
