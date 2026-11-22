# =============================================================================
# Database Module - RDS MySQL with Secrets Manager
# =============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  db_port     = 3306
}

# =============================================================================
# Random Password Generation
# =============================================================================

resource "random_password" "db" {
  length  = 24
  special = true

  # Exclude characters that RDS doesn't allow in passwords
  override_special = "!#$%&*()-_=+[]{}|:,.<>?"
}

# =============================================================================
# Secrets Manager
# =============================================================================

resource "aws_secretsmanager_secret" "db" {
  name        = "${local.name_prefix}-db-credentials"
  description = "Database credentials for ${local.name_prefix} RDS instance"

  # Set to 0 for clean destroy during development
  recovery_window_in_days = 0

  tags = {
    Name = "${local.name_prefix}-db-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
    host     = aws_db_instance.main.address
    port     = local.db_port
    dbname   = var.db_name
    engine   = "mysql"
  })

  depends_on = [aws_db_instance.main]
}

# =============================================================================
# DB Subnet Group
# =============================================================================

resource "aws_db_subnet_group" "main" {
  name        = "${local.name_prefix}-db-subnet-group"
  description = "Database subnet group for ${local.name_prefix}"
  subnet_ids  = var.subnet_ids

  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
}

# =============================================================================
# DB Parameter Group
# =============================================================================

resource "aws_db_parameter_group" "main" {
  name        = "${local.name_prefix}-db-params"
  family      = "mysql8.0"
  description = "Custom parameter group for ${local.name_prefix}"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  tags = {
    Name = "${local.name_prefix}-db-params"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# RDS Instance
# =============================================================================

resource "aws_db_instance" "main" {
  identifier = "${local.name_prefix}-mysql"

  # Engine
  engine               = "mysql"
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  parameter_group_name = aws_db_parameter_group.main.name

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 2 # Allow auto-scaling up to 2x
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result
  port     = local.db_port

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  # Backup
  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # Monitoring (Performance Insights off for Free Tier)
  performance_insights_enabled = false

  # Deletion settings for development
  skip_final_snapshot        = true
  delete_automated_backups   = true
  deletion_protection        = false
  apply_immediately          = true
  copy_tags_to_snapshot      = true
  auto_minor_version_upgrade = true

  tags = {
    Name = "${local.name_prefix}-mysql"
  }

  lifecycle {
    # Prevent accidental deletion in production
    # prevent_destroy = true
  }
}
