# =============================================================================
# Outputs - AWS 3-Tier Infrastructure
# =============================================================================

# -----------------------------------------------------------------------------
# Application Access
# -----------------------------------------------------------------------------

output "alb_url" {
  description = "URL to access the application via ALB"
  value       = module.alb.alb_url
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

# -----------------------------------------------------------------------------
# SSH Access
# -----------------------------------------------------------------------------

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = module.bastion.public_ip
}

output "bastion_ssh_command" {
  description = "SSH command to connect to the bastion host"
  value       = module.bastion.ssh_command
}

output "bastion_ssh_command_with_agent" {
  description = "SSH command with agent forwarding for jumping to private instances"
  value       = module.bastion.ssh_command_with_agent
}

output "ssh_to_private_instance" {
  description = "Instructions to SSH from bastion to a private instance"
  value       = module.bastion.ssh_to_private_instance
}

# -----------------------------------------------------------------------------
# Database
# -----------------------------------------------------------------------------

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.db_endpoint
}

output "rds_address" {
  description = "RDS instance hostname"
  value       = module.database.db_address
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  value       = module.database.db_secret_arn
}

output "db_name" {
  description = "Name of the database"
  value       = module.database.db_name
}

# -----------------------------------------------------------------------------
# Auto Scaling
# -----------------------------------------------------------------------------

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.compute.asg_name
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = module.compute.launch_template_id
}

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------

output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = module.monitoring.dashboard_url
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = module.monitoring.sns_topic_arn
}

output "cloudwatch_alarms" {
  description = "List of CloudWatch alarm names"
  value       = module.monitoring.alarm_names
}

# -----------------------------------------------------------------------------
# Network Information
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private app subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "List of private database subnet IDs"
  value       = module.vpc.database_subnet_ids
}

output "nat_gateway_public_ips" {
  description = "Public IP addresses of NAT Gateway(s)"
  value       = module.vpc.nat_gateway_public_ips
}

output "availability_zones" {
  description = "Availability zones used"
  value       = module.vpc.availability_zones
}

# -----------------------------------------------------------------------------
# Security Groups
# -----------------------------------------------------------------------------

output "security_groups" {
  description = "Security group IDs"
  value = {
    alb     = module.security.alb_security_group_id
    app     = module.security.app_security_group_id
    bastion = module.security.bastion_security_group_id
    db      = module.security.db_security_group_id
  }
}

# -----------------------------------------------------------------------------
# Quick Reference Commands
# -----------------------------------------------------------------------------

output "useful_commands" {
  description = "Helpful commands for testing and verification"
  value       = <<-EOT

    # Test the application
    curl ${module.alb.alb_url}
    curl ${module.alb.alb_url}/health
    curl ${module.alb.alb_url}/db

    # SSH to bastion
    ${module.bastion.ssh_command}

    # SSH with agent forwarding (to jump to private instances)
    ${module.bastion.ssh_command_with_agent}

    # Get DB credentials from Secrets Manager
    aws secretsmanager get-secret-value --secret-id ${module.database.db_secret_arn} --query SecretString --output text | jq .

    # View CloudWatch dashboard
    ${module.monitoring.dashboard_url}

    # CPU stress test (run from app instance via bastion)
    stress-ng --cpu 2 --timeout 600

  EOT
}
