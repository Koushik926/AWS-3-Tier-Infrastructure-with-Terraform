variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for the ASG"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of the app security group"
  type        = string
}

variable "instance_profile_name" {
  description = "Name of the IAM instance profile"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type        = number
  default     = 2
}

variable "health_check_grace_period" {
  description = "Time after instance launch before health checks start"
  type        = number
  default     = 180
}

variable "scaling_target_cpu" {
  description = "Target CPU utilization percentage for auto scaling"
  type        = number
  default     = 50
}

variable "user_data_vars" {
  description = "Variables to pass to the user data template"
  type = object({
    db_host       = string
    db_port       = number
    db_name       = string
    db_secret_arn = string
    aws_region    = string
    project_name  = string
    environment   = string
  })
}
