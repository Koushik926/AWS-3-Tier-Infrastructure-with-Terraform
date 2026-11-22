# =============================================================================
# AWS 3-Tier Infrastructure - Development Environment
# =============================================================================
# This configuration wires together all modules to create:
# - VPC with public, private app, and private DB subnets
# - Security groups and IAM roles
# - Application Load Balancer
# - Auto Scaling Group with EC2 instances
# - RDS MySQL database
# - Bastion host
# - CloudWatch monitoring and alarms
# =============================================================================

locals {
  name_prefix  = "${var.project_name}-${var.environment}"
  enable_https = var.acm_certificate_arn != ""
}

# =============================================================================
# VPC Module
# =============================================================================

module "vpc" {
  source = "../../modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  single_nat_gateway = var.single_nat_gateway
}

# =============================================================================
# Database Module (Created before Security for secret ARN)
# =============================================================================

module "database" {
  source = "../../modules/database"

  project_name      = var.project_name
  environment       = var.environment
  subnet_ids        = module.vpc.database_subnet_ids
  security_group_id = module.security.db_security_group_id
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  db_name           = var.db_name
  db_username       = var.db_username
  multi_az          = var.multi_az

  depends_on = [module.security]
}

# =============================================================================
# Security Module
# =============================================================================

module "security" {
  source = "../../modules/security"

  project_name  = var.project_name
  environment   = var.environment
  vpc_id        = module.vpc.vpc_id
  my_ip_cidr    = var.my_ip_cidr
  app_port      = var.app_port
  enable_https  = local.enable_https
  db_secret_arn = "" # Will be updated after database module
}

# Update security module with DB secret ARN for IAM policy
# This is handled in a second security module call or via data source
# For simplicity, we'll use a null_resource to update the policy

resource "aws_iam_role_policy" "app_secrets_updated" {
  name = "${local.name_prefix}-app-secrets-policy"
  role = module.security.app_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = module.database.db_secret_arn
      }
    ]
  })

  depends_on = [module.database, module.security]
}

# =============================================================================
# ALB Module
# =============================================================================

module "alb" {
  source = "../../modules/alb"

  project_name        = var.project_name
  environment         = var.environment
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.public_subnet_ids
  security_group_id   = module.security.alb_security_group_id
  target_port         = var.app_port
  acm_certificate_arn = var.acm_certificate_arn
  enable_access_logs  = var.enable_alb_access_logs
  access_logs_bucket  = var.alb_access_logs_bucket
}

# =============================================================================
# Compute Module
# =============================================================================

module "compute" {
  source = "../../modules/compute"

  project_name          = var.project_name
  environment           = var.environment
  subnet_ids            = module.vpc.private_subnet_ids
  security_group_id     = module.security.app_security_group_id
  instance_profile_name = module.security.app_instance_profile_name
  target_group_arn      = module.alb.target_group_arn
  instance_type         = var.app_instance_type
  key_pair_name         = var.key_pair_name
  min_size              = var.asg_min_size
  max_size              = var.asg_max_size
  desired_capacity      = var.asg_desired_capacity
  scaling_target_cpu    = var.scaling_target_cpu

  user_data_vars = {
    db_host       = module.database.db_address
    db_port       = module.database.db_port
    db_name       = module.database.db_name
    db_secret_arn = module.database.db_secret_arn
    aws_region    = var.aws_region
    project_name  = var.project_name
    environment   = var.environment
  }

  depends_on = [module.database, aws_iam_role_policy.app_secrets_updated]
}

# =============================================================================
# Bastion Module
# =============================================================================

module "bastion" {
  source = "../../modules/bastion"

  project_name          = var.project_name
  environment           = var.environment
  subnet_id             = module.vpc.public_subnet_ids[0]
  security_group_id     = module.security.bastion_security_group_id
  instance_profile_name = module.security.bastion_instance_profile_name
  key_pair_name         = var.key_pair_name
}

# =============================================================================
# Monitoring Module
# =============================================================================

module "monitoring" {
  source = "../../modules/monitoring"

  project_name            = var.project_name
  environment             = var.environment
  alert_email             = var.alert_email
  asg_name                = module.compute.asg_name
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  db_instance_identifier  = module.database.db_instance_identifier
  cpu_alarm_threshold     = var.cpu_alarm_threshold
}
