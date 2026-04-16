variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project prefix for resource names."
  type        = string
  default     = "surgtech-eks"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags to apply to supported AWS resources."
  type        = map(string)
  default     = {}
}

variable "cluster_version" {
  description = "EKS cluster version."
  type        = string
  default     = "1.30"
}

variable "node_instance_types" {
  description = "Node instance types for the EKS node group."
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_capacity_type" {
  description = "Use SPOT for lower cost or ON_DEMAND for stability."
  type        = string
  default     = "SPOT"

  validation {
    condition     = contains(["SPOT", "ON_DEMAND"], var.node_capacity_type)
    error_message = "node_capacity_type must be SPOT or ON_DEMAND."
  }
}

variable "desired_size" {
  description = "Desired number of nodes."
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Minimum nodes."
  type        = number
  default     = 1

  validation {
    condition     = var.min_size >= 0
    error_message = "min_size must be 0 or greater."
  }
}

variable "max_size" {
  description = "Maximum nodes."
  type        = number
  default     = 2

  validation {
    condition     = var.max_size >= var.min_size
    error_message = "max_size must be greater than or equal to min_size."
  }
}
