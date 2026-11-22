# Architecture Documentation

## Overview

This project implements a highly available 3-tier web application architecture on AWS using Terraform. The architecture follows AWS Well-Architected Framework principles for reliability, security, and cost optimization.

## Architecture Diagram

```
                                    ┌─────────────────────────────────────────────────────────────────────┐
                                    │                         AWS Cloud                                    │
                                    │                                                                       │
    ┌─────────┐                    │  ┌─────────────────────────────────────────────────────────────────┐  │
    │         │                    │  │                           VPC                                    │  │
    │  Users  │                    │  │                       10.0.0.0/16                                │  │
    │         │                    │  │                                                                   │  │
    └────┬────┘                    │  │  ┌──────────────────────────────────────────────────────────┐   │  │
         │                         │  │  │              Public Subnets (10.0.1-2.0/24)              │   │  │
         │                         │  │  │                                                          │   │  │
         ▼                         │  │  │   ┌─────────────────┐    ┌─────────────────┐           │   │  │
    ┌─────────┐                    │  │  │   │    AZ-1a        │    │    AZ-1b        │           │   │  │
    │   IGW   │◄───────────────────┼──┼──┼───│                 │    │                 │           │   │  │
    └────┬────┘                    │  │  │   │  ┌───────────┐  │    │  ┌───────────┐  │           │   │  │
         │                         │  │  │   │  │    ALB    │◄─┼────┼─►│    ALB    │  │           │   │  │
         │                         │  │  │   │  └───────────┘  │    │  └───────────┘  │           │   │  │
         │                         │  │  │   │  ┌───────────┐  │    │                 │           │   │  │
         │                         │  │  │   │  │  NAT GW   │  │    │                 │           │   │  │
         │                         │  │  │   │  └─────┬─────┘  │    │                 │           │   │  │
         │                         │  │  │   │  ┌───────────┐  │    │                 │           │   │  │
         │                         │  │  │   │  │  Bastion  │  │    │                 │           │   │  │
         │                         │  │  │   │  └───────────┘  │    │                 │           │   │  │
         │                         │  │  │   └─────────────────┘    └─────────────────┘           │   │  │
         │                         │  │  └──────────────────────────────────────────────────────────┘   │  │
         │                         │  │                               │                                  │  │
         │                         │  │  ┌──────────────────────────────────────────────────────────┐   │  │
         │                         │  │  │              Private App Subnets (10.0.11-12.0/24)       │   │  │
         │                         │  │  │                                                          │   │  │
         │                         │  │  │   ┌─────────────────┐    ┌─────────────────┐           │   │  │
         │                         │  │  │   │    AZ-1a        │    │    AZ-1b        │           │   │  │
         │                         │  │  │   │                 │    │                 │           │   │  │
         │                         │  │  │   │  ┌───────────┐  │    │  ┌───────────┐  │  ┌─────┐  │   │  │
         └─────────────────────────┼──┼──┼───┼─►│   EC2     │◄─┼────┼─►│   EC2     │◄─┼──│ ASG │  │   │  │
                                   │  │  │   │  │   App     │  │    │  │   App     │  │  └─────┘  │   │  │
                                   │  │  │   │  └─────┬─────┘  │    │  └─────┬─────┘  │           │   │  │
                                   │  │  │   │        │        │    │        │        │           │   │  │
                                   │  │  │   └────────┼────────┘    └────────┼────────┘           │   │  │
                                   │  │  └────────────┼─────────────────────┼──────────────────────┘   │  │
                                   │  │               │                     │                          │  │
                                   │  │  ┌────────────┼─────────────────────┼──────────────────────┐   │  │
                                   │  │  │            │  Private DB Subnets │(10.0.21-22.0/24)     │   │  │
                                   │  │  │            │                     │                      │   │  │
                                   │  │  │   ┌───────────────────────────────────────────────┐    │   │  │
                                   │  │  │   │                                               │    │   │  │
                                   │  │  │   │            ┌───────────────────┐              │    │   │  │
                                   │  │  │   │            │   RDS MySQL       │              │    │   │  │
                                   │  │  │   │            │   (Primary)       │              │    │   │  │
                                   │  │  │   │            └───────────────────┘              │    │   │  │
                                   │  │  │   │                                               │    │   │  │
                                   │  │  │   └───────────────────────────────────────────────┘    │   │  │
                                   │  │  │                                                        │   │  │
                                   │  │  └────────────────────────────────────────────────────────┘   │  │
                                   │  │                                                                │  │
                                   │  └────────────────────────────────────────────────────────────────┘  │
                                   │                                                                       │
                                   │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
                                   │  │   Secrets    │  │  CloudWatch  │  │     SNS      │               │
                                   │  │   Manager    │  │  Dashboard   │  │    Topic     │               │
                                   │  └──────────────┘  └──────────────┘  └──────────────┘               │
                                   │                                                                       │
                                   └───────────────────────────────────────────────────────────────────────┘
```

## Component Details

### Networking (VPC Module)

| Component | CIDR/Details | Purpose |
|-----------|--------------|---------|
| VPC | 10.0.0.0/16 | Isolated network for all resources |
| Public Subnets | 10.0.1.0/24, 10.0.2.0/24 | ALB, NAT Gateway, Bastion |
| Private App Subnets | 10.0.11.0/24, 10.0.12.0/24 | EC2 application instances |
| Private DB Subnets | 10.0.21.0/24, 10.0.22.0/24 | RDS database (no internet route) |
| Internet Gateway | - | Enables internet access for public subnets |
| NAT Gateway | Elastic IP | Enables outbound internet for private subnets |

### Web Tier (ALB Module)

- **Type**: Application Load Balancer (Layer 7)
- **Scheme**: Internet-facing
- **Subnets**: Both public subnets (cross-AZ)
- **Health Check**: `/health` endpoint (15s interval)
- **Listeners**: HTTP (80), HTTPS (443) with redirect if cert provided

### Application Tier (Compute Module)

- **Instance Type**: t3.micro (Free Tier eligible)
- **AMI**: Amazon Linux 2023 (looked up dynamically)
- **Auto Scaling**:
  - Min: 2 instances
  - Max: 4 instances
  - Target CPU: 50%
- **Health Check**: ELB-based with 180s grace period
- **Instance Refresh**: Rolling updates (50% min healthy)

### Database Tier (Database Module)

- **Engine**: MySQL 8.0
- **Instance Class**: db.t3.micro (Free Tier eligible)
- **Storage**: 20 GB gp3, encrypted
- **Multi-AZ**: Configurable (default: false for cost)
- **Backup**: 1 day retention
- **Credentials**: Stored in Secrets Manager

### Security (Security Module)

| IAM Role | Attached Policies | Purpose |
|----------|-------------------|---------|
| App Role | SSM Core, CloudWatch Agent, Secrets Access | EC2 application instances |
| Bastion Role | SSM Core | Jump box access |

### Monitoring (Monitoring Module)

**CloudWatch Alarms:**
1. ASG CPU > 70%
2. ALB Unhealthy Hosts > 0
3. ALB Healthy Hosts < 2
4. ALB 5xx Errors > 10
5. ALB Response Time p90 > 1s
6. RDS CPU > 80%
7. RDS Free Storage < 2GB

## Data Flow

### User Request Flow

```
User Browser
    │
    ▼
Internet Gateway
    │
    ▼
ALB (Public Subnets)
    │
    ├── Health Check: /health (every 15s)
    │
    ▼
EC2 Instances (Private Subnets)
    │
    ├── App retrieves DB credentials from Secrets Manager
    │
    ▼
RDS MySQL (Isolated DB Subnets)
```

### Administrative Access Flow

```
Admin Workstation
    │
    ▼
Bastion Host (Public Subnet, SSH from allowed IP)
    │
    ▼
EC2 Instances (Private Subnet, SSH from Bastion SG)
    │
    ▼
RDS MySQL (MySQL client from App SG)
```

### Scaling Flow

```
CloudWatch Metrics
    │
    ▼
CPU > 50% Target
    │
    ▼
Auto Scaling Policy
    │
    ▼
Launch New Instance
    │
    ▼
Register with Target Group
    │
    ▼
Health Check Passes
    │
    ▼
Traffic Served
```

## Security Considerations

1. **Defense in Depth**: Multiple network layers (public → private app → private DB)
2. **Least Privilege**: Security groups reference each other, not wide CIDRs
3. **Encryption**: EBS volumes encrypted, RDS storage encrypted, Secrets Manager
4. **Access Control**: Bastion limited to specific IP, SSM as backup
5. **Monitoring**: VPC Flow Logs, CloudWatch alarms, CloudTrail integration
