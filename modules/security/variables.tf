variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "my_ip_cidr" {
  description = "Your public IP address in CIDR notation for SSH access to bastion"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.my_ip_cidr)) && can(regex("/32$", var.my_ip_cidr))
    error_message = "my_ip_cidr must be a valid IPv4 CIDR with /32 suffix."
  }
}

variable "app_port" {
  description = "Port on which the application runs"
  type        = number
  default     = 80
}

variable "db_port" {
  description = "Port on which the database runs"
  type        = number
  default     = 3306
}

variable "enable_https" {
  description = "Enable HTTPS (443) on the ALB security group"
  type        = bool
  default     = false
}

variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  type        = string
  default     = ""
}
