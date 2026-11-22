# =============================================================================
# Project Configuration
# =============================================================================

variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
  default     = "aws-3tier"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
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

# =============================================================================
# Network Configuration
# =============================================================================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets (cost savings). Set to false for high availability (one NAT per AZ)."
  type        = bool
  default     = true
}

# =============================================================================
# Security Configuration
# =============================================================================

variable "my_ip_cidr" {
  description = "Your public IP address in CIDR notation (e.g., 203.0.113.50/32) for SSH access to bastion"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.my_ip_cidr)) && can(regex("/32$", var.my_ip_cidr))
    error_message = "my_ip_cidr must be a valid IPv4 CIDR block with /32 suffix (e.g., 203.0.113.50/32)."
  }
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair for SSH access"
  type        = string

  validation {
    condition     = length(var.key_pair_name) > 0
    error_message = "Key pair name cannot be empty."
  }
}

# =============================================================================
# Compute Configuration
# =============================================================================

variable "app_instance_type" {
  description = "EC2 instance type for application servers"
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "Port on which the application runs"
  type        = number
  default     = 80
}

variable "asg_min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

# =============================================================================
# Database Configuration
# =============================================================================

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "appdb"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]*$", var.db_name))
    error_message = "Database name must start with a letter and contain only alphanumeric characters."
  }
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "admin"
  sensitive   = true

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]*$", var.db_username))
    error_message = "Database username must start with a letter and contain only alphanumeric characters."
  }
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB for RDS"
  type        = number
  default     = 20
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for RDS (increases cost)"
  type        = bool
  default     = false
}

# =============================================================================
# Load Balancer Configuration
# =============================================================================

variable "acm_certificate_arn" {
  description = "ARN of ACM certificate for HTTPS. If not provided, only HTTP will be configured."
  type        = string
  default     = ""
}

variable "enable_alb_access_logs" {
  description = "Enable access logging for the ALB"
  type        = bool
  default     = false
}

variable "alb_access_logs_bucket" {
  description = "S3 bucket name for ALB access logs (required if enable_alb_access_logs is true)"
  type        = string
  default     = ""
}

# =============================================================================
# Monitoring Configuration
# =============================================================================

variable "alert_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_email))
    error_message = "Must be a valid email address."
  }
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization percentage threshold for scaling alarm"
  type        = number
  default     = 70
}

variable "scaling_target_cpu" {
  description = "Target CPU utilization percentage for auto scaling"
  type        = number
  default     = 50
}
