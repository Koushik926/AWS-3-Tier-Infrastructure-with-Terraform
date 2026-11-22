# ALB Module

Creates an internet-facing Application Load Balancer with target group and listeners.

## Features

- Internet-facing ALB across multiple public subnets
- Target group with configurable health checks
- HTTP listener (forwards traffic or redirects to HTTPS)
- Optional HTTPS listener with ACM certificate
- Invalid header field dropping enabled
- Optional access logging to S3

## Architecture

```
                    Internet
                        │
                        ▼
            ┌───────────────────────┐
            │          ALB          │
            │   (Public Subnets)    │
            │                       │
            │   Port 80  → Forward  │
            │   Port 443 → Forward  │
            │      (if HTTPS)       │
            └───────────┬───────────┘
                        │
                        ▼
            ┌───────────────────────┐
            │    Target Group       │
            │                       │
            │  Health: /health      │
            │  Interval: 15s        │
            │  Healthy: 2           │
            │  Unhealthy: 3         │
            └───────────────────────┘
                        │
                        ▼
            ┌─────────────────────┐
            │   EC2 Instances     │
            │  (Private Subnets)  │
            └─────────────────────┘
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| vpc_id | ID of the VPC | `string` | n/a | yes |
| subnet_ids | List of public subnet IDs | `list(string)` | n/a | yes |
| security_group_id | ID of the ALB security group | `string` | n/a | yes |
| target_port | Port for targets | `number` | `80` | no |
| health_check_path | Health check path | `string` | `"/health"` | no |
| health_check_interval | Seconds between health checks | `number` | `15` | no |
| healthy_threshold | Checks to be healthy | `number` | `2` | no |
| unhealthy_threshold | Checks to be unhealthy | `number` | `3` | no |
| acm_certificate_arn | ACM cert ARN for HTTPS | `string` | `""` | no |
| enable_access_logs | Enable ALB access logs | `bool` | `false` | no |
| access_logs_bucket | S3 bucket for access logs | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_id | ID of the ALB |
| alb_arn | ARN of the ALB |
| alb_arn_suffix | ARN suffix (for CloudWatch) |
| alb_dns_name | DNS name of the ALB |
| alb_url | Full HTTP URL |
| target_group_arn | ARN of target group |
| target_group_arn_suffix | ARN suffix (for CloudWatch) |
| http_listener_arn | ARN of HTTP listener |
| https_listener_arn | ARN of HTTPS listener |

## Health Check Configuration

The target group health check:
- **Path**: `/health` (should return 200 without DB dependency)
- **Interval**: 15 seconds
- **Healthy threshold**: 2 consecutive successes
- **Unhealthy threshold**: 3 consecutive failures
- **Timeout**: 5 seconds
- **Matcher**: HTTP 200

## HTTPS Configuration

To enable HTTPS:
1. Create/import an ACM certificate in the same region
2. Set `acm_certificate_arn` to the certificate ARN
3. HTTP traffic will automatically redirect to HTTPS

## Cost

ALB pricing (ap-south-1):
- ~$0.0225/hour (~$16/month)
- Plus LCU charges based on traffic
