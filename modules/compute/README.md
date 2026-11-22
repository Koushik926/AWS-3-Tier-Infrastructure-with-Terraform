# Compute Module

Creates EC2 instances via Launch Template and Auto Scaling Group with target tracking scaling.

## Features

- Launch Template with Amazon Linux 2023 (looked up dynamically)
- IMDSv2 required for security
- Encrypted gp3 root volume
- Auto Scaling Group across multiple private subnets
- ELB health checks for self-healing
- Instance refresh for rolling deployments
- Target tracking scaling policy (CPU-based)

## Architecture

```
                    ┌─────────────────────────────────────────┐
                    │          Auto Scaling Group             │
                    │                                         │
                    │   Min: 2 │ Desired: 2 │ Max: 4         │
                    │                                         │
                    │   ┌─────────────┐  ┌─────────────┐     │
                    │   │   AZ-1      │  │   AZ-2      │     │
                    │   │  Private    │  │  Private    │     │
                    │   │  Subnet     │  │  Subnet     │     │
                    │   │             │  │             │     │
                    │   │  ┌───────┐  │  │  ┌───────┐  │     │
                    │   │  │ EC2   │  │  │  │ EC2   │  │     │
                    │   │  │ App   │  │  │  │ App   │  │     │
                    │   │  └───────┘  │  │  └───────┘  │     │
                    │   │             │  │             │     │
                    │   └─────────────┘  └─────────────┘     │
                    │                                         │
                    └─────────────────────────────────────────┘
                                        │
                                        ▼
                              Target Tracking
                              CPU Target: 50%
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| vpc_id | ID of the VPC | `string` | n/a | yes |
| subnet_ids | List of private subnet IDs | `list(string)` | n/a | yes |
| security_group_id | ID of the app security group | `string` | n/a | yes |
| instance_profile_name | IAM instance profile name | `string` | n/a | yes |
| target_group_arn | ARN of ALB target group | `string` | n/a | yes |
| instance_type | EC2 instance type | `string` | `"t3.micro"` | no |
| key_pair_name | EC2 key pair name | `string` | n/a | yes |
| min_size | Minimum instances | `number` | `2` | no |
| max_size | Maximum instances | `number` | `4` | no |
| desired_capacity | Desired instances | `number` | `2` | no |
| health_check_grace_period | Seconds before health checks | `number` | `180` | no |
| scaling_target_cpu | Target CPU % | `number` | `50` | no |
| user_data_vars | Variables for user data | `object` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| launch_template_id | ID of launch template |
| launch_template_arn | ARN of launch template |
| asg_id | ID of Auto Scaling Group |
| asg_arn | ARN of Auto Scaling Group |
| asg_name | Name of Auto Scaling Group |
| ami_id | AMI ID used |
| scaling_policy_arn | ARN of scaling policy |

## Scaling Behavior

**Scale Out**: When average CPU > 50% for sustained period
**Scale In**: When average CPU < 50% for sustained period

The ASG maintains:
- Minimum 2 instances (HA across AZs)
- Maximum 4 instances (cost control)
- Target CPU utilization of 50%

## Self-Healing

The ASG automatically replaces instances that:
- Fail ELB health checks (3 consecutive failures)
- Are terminated manually
- Have their underlying host fail

## Instance Refresh

Launch template changes trigger rolling updates:
- 50% minimum healthy instances maintained
- Instances replaced one at a time
- Automatic rollback on deployment failure

## Cost

Free Tier eligible with `t3.micro`:
- 750 hours/month of t2.micro or t3.micro
- Instances in private subnets have no public IPs
