output "instance_id" {
  description = "ID of the bastion instance"
  value       = aws_instance.bastion.id
}

output "public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "public_dns" {
  description = "Public DNS name of the bastion host"
  value       = aws_instance.bastion.public_dns
}

output "private_ip" {
  description = "Private IP address of the bastion host"
  value       = aws_instance.bastion.private_ip
}

output "ssh_command" {
  description = "SSH command to connect to the bastion host"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ec2-user@${aws_instance.bastion.public_ip}"
}

output "ssh_command_with_agent" {
  description = "SSH command with agent forwarding for jumping to private instances"
  value       = "ssh -A -i ~/.ssh/${var.key_pair_name}.pem ec2-user@${aws_instance.bastion.public_ip}"
}

output "ssh_to_private_instance" {
  description = "Command to SSH from bastion to a private instance (run from bastion)"
  value       = "# From your local machine (with agent forwarding):\nssh -A -i ~/.ssh/${var.key_pair_name}.pem ec2-user@${aws_instance.bastion.public_ip}\n\n# Then from the bastion, SSH to a private instance:\nssh ec2-user@<private-instance-ip>"
}

output "ami_id" {
  description = "ID of the AMI used for the bastion"
  value       = data.aws_ami.amazon_linux_2023.id
}
