# =============================================================================
# Bastion Module - Jump Box for SSH Access
# =============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# =============================================================================
# Data Sources
# =============================================================================

# Get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# =============================================================================
# Bastion EC2 Instance
# =============================================================================

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_pair_name

  iam_instance_profile = var.instance_profile_name

  # IMDSv2 required for security
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # Encrypted root volume
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "${local.name_prefix}-bastion-volume"
    }
  }

  # Simple user data for bastion (just updates)
  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y mariadb105 jq
  EOF
  )

  tags = {
    Name = "${local.name_prefix}-bastion"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}
