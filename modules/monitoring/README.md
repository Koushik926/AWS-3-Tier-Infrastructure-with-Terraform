# Monitoring Module

Creates CloudWatch alarms, SNS topic for notifications, and a dashboard for the 3-tier infrastructure.

## Features

- SNS topic with email subscription for alerts
- 7 CloudWatch alarms covering ASG, ALB, and RDS
- Comprehensive CloudWatch dashboard

## Alarms

| Alarm | Metric | Threshold | Period | Purpose |
|-------|--------|-----------|--------|---------|
| ASG CPU High | EC2 CPUUtilization | > 70% | 2 × 5min | Triggers scale-out |
| ALB Unhealthy Hosts | UnHealthyHostCount | > 0 | 2 × 1min | Detects failed instances |
| ALB Healthy Hosts Low | HealthyHostCount | < 2 | 2 × 1min | Availability warning |
| ALB 5xx Errors | HTTPCode_Target_5XX | > 10 | 5min | Application errors |
| ALB Response Time | TargetResponseTime p90 | > 1s | 2 × 5min | Performance degradation |
| RDS CPU High | RDS CPUUtilization | > 80% | 2 × 5min | Database overload |
| RDS Storage Low | FreeStorageSpace | < 2GB | 2 × 5min | Disk space warning |

## Dashboard Widgets

The dashboard displays:

**Row 1 - Health Overview:**
- ASG CPU Utilization (with alarm threshold line)
- ALB Healthy/Unhealthy Host Count
- ALB Request Count

**Row 2 - ALB Performance:**
- HTTP Status Codes (2xx, 4xx, 5xx)
- Response Time (p50, p90, p99)
- RDS CPU Utilization

**Row 3 - Database Metrics:**
- RDS Database Connections
- RDS Free Storage Space
- RDS Read/Write IOPS

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| alert_email | Email for notifications | `string` | n/a | yes |
| asg_name | Auto Scaling Group name | `string` | n/a | yes |
| alb_arn_suffix | ALB ARN suffix | `string` | n/a | yes |
| target_group_arn_suffix | Target group ARN suffix | `string` | n/a | yes |
| db_instance_identifier | RDS instance identifier | `string` | n/a | yes |
| cpu_alarm_threshold | ASG CPU threshold | `number` | `70` | no |
| rds_cpu_threshold | RDS CPU threshold | `number` | `80` | no |
| rds_storage_threshold_gb | RDS storage threshold (GB) | `number` | `2` | no |
| alb_5xx_threshold | 5xx error count threshold | `number` | `10` | no |
| response_time_threshold | Response time threshold (s) | `number` | `1` | no |
| min_healthy_hosts | Minimum healthy hosts | `number` | `2` | no |

## Outputs

| Name | Description |
|------|-------------|
| sns_topic_arn | ARN of SNS topic |
| sns_topic_name | Name of SNS topic |
| dashboard_name | CloudWatch dashboard name |
| dashboard_url | Direct link to dashboard |
| alarm_arns | Map of alarm ARNs |
| alarm_names | List of alarm names |

## Important Notes

⚠️ **Email Confirmation Required**

After `terraform apply`, you must confirm the SNS email subscription:
1. Check your email inbox for a message from AWS Notifications
2. Click the "Confirm subscription" link
3. Alarms will not send emails until confirmed

## Testing Alarms

### CPU Alarm Test

```bash
# SSH to an app instance via bastion and run:
stress-ng --cpu 2 --timeout 600
```

This will max out CPU and trigger the alarm within 10 minutes.

### Unhealthy Host Test

```bash
# Stop nginx on an instance
sudo systemctl stop nginx
```

The health check will fail and trigger the unhealthy host alarm.

## Cost

- SNS: First 1 million requests free, then $0.50 per 1M
- CloudWatch Alarms: $0.10/alarm/month (7 alarms = $0.70/month)
- CloudWatch Dashboard: First 3 dashboards free
- CloudWatch Metrics: Standard metrics included, custom metrics extra
