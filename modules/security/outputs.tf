output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion.id
}

output "app_security_group_id" {
  description = "ID of the app security group"
  value       = aws_security_group.app.id
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.db.id
}

output "app_instance_profile_name" {
  description = "Name of the app instance profile"
  value       = aws_iam_instance_profile.app.name
}

output "app_instance_profile_arn" {
  description = "ARN of the app instance profile"
  value       = aws_iam_instance_profile.app.arn
}

output "app_role_arn" {
  description = "ARN of the app IAM role"
  value       = aws_iam_role.app.arn
}

output "app_role_name" {
  description = "Name of the app IAM role"
  value       = aws_iam_role.app.name
}

output "bastion_instance_profile_name" {
  description = "Name of the bastion instance profile"
  value       = aws_iam_instance_profile.bastion.name
}

output "bastion_instance_profile_arn" {
  description = "ARN of the bastion instance profile"
  value       = aws_iam_instance_profile.bastion.arn
}

output "bastion_role_arn" {
  description = "ARN of the bastion IAM role"
  value       = aws_iam_role.bastion.arn
}
