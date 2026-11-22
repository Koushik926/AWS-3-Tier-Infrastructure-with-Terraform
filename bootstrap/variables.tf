variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
  default     = "aws-3tier"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-south-1"
}

variable "owner" {
  description = "Owner tag for resources"
  type        = string
  default     = "R Koushik"
}
