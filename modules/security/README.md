# Security Module

Creates security groups and IAM roles with least-privilege access for the 3-tier architecture.

## Features

- Security groups that reference each other by ID (not wide CIDRs)
- Least-privilege IAM roles for app and bastion instances
- SSH access to bastion restricted to a single IP
- Database accessible only from app tier

## Security Groups

| Name | Inbound | Outbound | Purpose |
|------|---------|----------|---------|
| `alb_sg` | 80, 443 from 0.0.0.0/0 | App port to `app_sg` | Internet-facing load balancer |
| `bastion_sg` | 22 from `my_ip_cidr` | 22 to `app_sg`, 443 to internet | Jump box for SSH access |
| `app_sg` | App port from `alb_sg`, 22 from `bastion_sg` | 443 to internet, 3306 to `db_sg` | Application servers |
| `db_sg` | 3306 from `app_sg` only | None | Database isolation |

## IAM Roles

### App Role
- `AmazonSSMManagedInstanceCore` - Session Manager access
- `CloudWatchAgentServerPolicy` - CloudWatch metrics and logs
- Inline policy for `secretsmanager:GetSecretValue` on the DB secret only

### Bastion Role
- `AmazonSSMManagedInstanceCore` - Session Manager access (alternative to SSH)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| vpc_id | ID of the VPC | `string` | n/a | yes |
| my_ip_cidr | Your IP in CIDR notation (/32) | `string` | n/a | yes |
| app_port | Application port | `number` | `80` | no |
| db_port | Database port | `number` | `3306` | no |
| enable_https | Enable HTTPS on ALB SG | `bool` | `false` | no |
| db_secret_arn | ARN of the DB secret | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_security_group_id | ID of the ALB security group |
| bastion_security_group_id | ID of the bastion security group |
| app_security_group_id | ID of the app security group |
| db_security_group_id | ID of the database security group |
| app_instance_profile_name | Name of the app instance profile |
| bastion_instance_profile_name | Name of the bastion instance profile |

## Security Design

```
                    Internet
                        │
                        ▼
            ┌───────────────────────┐
            │  ALB Security Group   │
            │  IN: 80, 443 (any)    │
            │  OUT: 80 → app_sg     │
            └───────────┬───────────┘
                        │
         ┌──────────────┼──────────────┐
         │              │              │
         ▼              ▼              ▼
┌─────────────────┐  ┌─────────────────────┐
│ Bastion SG      │  │  App Security Group │
│ IN: 22 (my IP)  │→→│  IN: 80 (alb_sg)    │
│ OUT: 22→app_sg  │  │      22 (bastion_sg)│
└─────────────────┘  │  OUT: 443 (internet)│
                     │       3306→db_sg    │
                     └──────────┬──────────┘
                                │
                                ▼
                     ┌─────────────────────┐
                     │  DB Security Group  │
                     │  IN: 3306 (app_sg)  │
                     │  OUT: None          │
                     └─────────────────────┘
```
