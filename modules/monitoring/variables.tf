variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "alert_email" {
  description = "Email address for alarm notifications"
  type        = string
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB (for CloudWatch dimensions)"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the target group (for CloudWatch dimensions)"
  type        = string
}

variable "db_instance_identifier" {
  description = "Identifier of the RDS instance"
  type        = string
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization percentage threshold for ASG alarm"
  type        = number
  default     = 70
}

variable "rds_cpu_threshold" {
  description = "CPU utilization percentage threshold for RDS alarm"
  type        = number
  default     = 80
}

variable "rds_storage_threshold_gb" {
  description = "Free storage threshold in GB for RDS alarm"
  type        = number
  default     = 2
}

variable "alb_5xx_threshold" {
  description = "Number of 5xx errors to trigger alarm"
  type        = number
  default     = 10
}

variable "response_time_threshold" {
  description = "Target response time p90 threshold in seconds"
  type        = number
  default     = 1
}

variable "min_healthy_hosts" {
  description = "Minimum number of healthy hosts before alarm"
  type        = number
  default     = 2
}
