# VPC Module

Creates a production-ready VPC with public, private app, and private database subnets across 2 Availability Zones.

## Features

- VPC with DNS hostnames and DNS support enabled
- 6 subnets across 2 AZs (2 public, 2 private app, 2 private DB)
- Internet Gateway for public internet access
- NAT Gateway(s) for private subnet outbound traffic
- Isolated database subnets with no internet route
- VPC Flow Logs to CloudWatch for network monitoring

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                            VPC                                   │
│  ┌─────────────────────────┐  ┌─────────────────────────┐       │
│  │         AZ-1            │  │         AZ-2            │       │
│  │  ┌───────────────────┐  │  │  ┌───────────────────┐  │       │
│  │  │  Public Subnet    │  │  │  │  Public Subnet    │  │       │
│  │  │  10.0.1.0/24      │  │  │  │  10.0.2.0/24      │  │       │
│  │  │  [NAT GW]         │  │  │  │                   │  │       │
│  │  └───────────────────┘  │  │  └───────────────────┘  │       │
│  │  ┌───────────────────┐  │  │  ┌───────────────────┐  │       │
│  │  │  Private Subnet   │  │  │  │  Private Subnet   │  │       │
│  │  │  10.0.11.0/24     │  │  │  │  10.0.12.0/24     │  │       │
│  │  │  [App Tier]       │  │  │  │  [App Tier]       │  │       │
│  │  └───────────────────┘  │  │  └───────────────────┘  │       │
│  │  ┌───────────────────┐  │  │  ┌───────────────────┐  │       │
│  │  │  DB Subnet        │  │  │  │  DB Subnet        │  │       │
│  │  │  10.0.21.0/24     │  │  │  │  10.0.22.0/24     │  │       │
│  │  │  [No Internet]    │  │  │  │  [No Internet]    │  │       │
│  │  └───────────────────┘  │  │  └───────────────────┘  │       │
│  └─────────────────────────┘  └─────────────────────────┘       │
└─────────────────────────────────────────────────────────────────┘
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project, used for resource naming | `string` | n/a | yes |
| environment | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| vpc_cidr | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| single_nat_gateway | Use a single NAT Gateway (cost savings) | `bool` | `true` | no |
| flow_log_retention_days | Days to retain VPC Flow Logs | `number` | `7` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_cidr | CIDR block of the VPC |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private app subnet IDs |
| database_subnet_ids | List of private database subnet IDs |
| nat_gateway_ids | List of NAT Gateway IDs |
| availability_zones | List of availability zones used |
| flow_log_group_name | CloudWatch Log Group for VPC Flow Logs |

## Cost Considerations

⚠️ **NAT Gateway costs approximately $0.045/hour (~$32/month) plus data transfer charges.**

For development/testing:
- Set `single_nat_gateway = true` (default) to use one NAT Gateway
- Remember to run `terraform destroy` after testing

For production:
- Set `single_nat_gateway = false` for high availability (one NAT per AZ)
