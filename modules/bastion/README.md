# Bastion Module

Creates a bastion (jump box) host for secure SSH access to private instances.

## Features

- Single t3.micro instance in a public subnet
- IMDSv2 required for enhanced security
- Encrypted root volume
- MySQL client pre-installed for database access
- SSM Agent for Session Manager as backup access method

## Security

- SSH access restricted to a single IP (`my_ip_cidr`)
- No direct access to private instances from internet
- Minimal IAM role (SSM only)
- Acts as a gateway for all administrative access

## Usage

### Connect to Bastion

```bash
# Basic SSH connection
ssh -i ~/.ssh/your-key.pem ec2-user@<bastion-public-ip>

# With agent forwarding (recommended for jumping to private instances)
ssh -A -i ~/.ssh/your-key.pem ec2-user@<bastion-public-ip>
```

### Jump to Private Instance

```bash
# Step 1: Add your key to SSH agent (on local machine)
ssh-add ~/.ssh/your-key.pem

# Step 2: Connect to bastion with agent forwarding
ssh -A -i ~/.ssh/your-key.pem ec2-user@<bastion-public-ip>

# Step 3: From bastion, SSH to private instance
ssh ec2-user@<private-instance-ip>
```

### Alternative: Session Manager

If SSH is blocked or keys are unavailable:

```bash
aws ssm start-session --target <instance-id> --region ap-south-1
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| subnet_id | Public subnet ID | `string` | n/a | yes |
| security_group_id | Bastion security group ID | `string` | n/a | yes |
| instance_profile_name | IAM instance profile name | `string` | n/a | yes |
| key_pair_name | EC2 key pair name | `string` | n/a | yes |
| instance_type | Instance type | `string` | `"t3.micro"` | no |

## Outputs

| Name | Description |
|------|-------------|
| instance_id | ID of the bastion instance |
| public_ip | Public IP address |
| public_dns | Public DNS name |
| private_ip | Private IP address |
| ssh_command | Ready-to-use SSH command |
| ssh_command_with_agent | SSH command with agent forwarding |
| ami_id | AMI ID used |

## Why Both Bastion and SSM?

**Bastion Host:**
- Traditional, well-understood access pattern
- Works with standard SSH tools and workflows
- No dependency on AWS CLI on client machine
- Supports agent forwarding for key-based auth to private instances

**SSM Session Manager:**
- No need to manage SSH keys
- No need to open port 22 at all
- Full audit trail in CloudTrail
- Works even if bastion is unavailable

Having both provides flexibility and redundancy for administrative access.

## Cost

- t3.micro: Free Tier eligible (750 hours/month)
- Public IP: Free while instance is running
- Stopped instance: No compute charges, but EBS charges apply
