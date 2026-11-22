# Testing and Results

## Test Cases

| ID | Test | Steps | Expected Result | Actual Result | Status |
|----|------|-------|-----------------|---------------|--------|
| TC1 | Load Balancing | 1. Run `curl $ALB_URL` multiple times<br>2. Check instance ID in response | Different instance IDs/AZs appear | | ⬜ |
| TC2 | Health Check | 1. Run `curl $ALB_URL/health` | Returns 200 `{"status":"ok"}` | | ⬜ |
| TC3 | Database Connectivity | 1. Run `curl $ALB_URL/db`<br>2. Refresh multiple times | Visit count increments | | ⬜ |
| TC4 | Self-Healing | 1. Terminate one EC2 instance manually<br>2. Wait 5 minutes | ASG launches replacement, ALB continues serving | | ⬜ |
| TC5 | CPU Stress/Scale-Out | 1. SSH to instance via bastion<br>2. Run `stress-ng --cpu 2 --timeout 600`<br>3. Wait 10 minutes | CPU alarm fires, SNS email received, new instance launched | | ⬜ |
| TC6 | RDS Not Public | 1. Try to connect to RDS endpoint from local machine | Connection times out | | ⬜ |
| TC7 | SSH Bastion Only | 1. Try SSH directly to private instance IP<br>2. SSH through bastion | Direct fails, via bastion succeeds | | ⬜ |
| TC8 | Health Check Failure | 1. SSH to instance<br>2. Run `sudo systemctl stop nginx`<br>3. Wait 5 minutes | Unhealthy alarm fires, instance replaced | | ⬜ |

## Detailed Test Procedures

### TC1: Load Balancing Verification

```bash
# Get ALB URL
ALB_URL=$(terraform output -raw alb_url)

# Run multiple requests and grep for instance ID
for i in {1..10}; do
  curl -s $ALB_URL | grep -o 'i-[a-z0-9]*'
done
```

**Expected**: You should see at least 2 different instance IDs, indicating traffic is distributed across AZs.

---

### TC2: Health Check Endpoint

```bash
curl -s $ALB_URL/health | jq .
```

**Expected Output**:
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00.000000",
  "instance": "i-0abc123def456"
}
```

---

### TC3: Database Connectivity

```bash
# First request creates table and inserts first row
curl -s $ALB_URL/db | jq .

# Subsequent requests increment count
curl -s $ALB_URL/db | jq .
curl -s $ALB_URL/db | jq .
```

**Expected Output**:
```json
{
  "status": "success",
  "message": "Database connection successful",
  "total_visits": 3,
  "current_instance": "i-0abc123def456",
  "availability_zone": "ap-south-1a",
  "recent_visits": [...]
}
```

---

### TC4: Self-Healing Test

```bash
# Get instance ID
INSTANCE_ID=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $(terraform output -raw asg_name) \
  --query 'AutoScalingGroups[0].Instances[0].InstanceId' --output text)

echo "Terminating instance: $INSTANCE_ID"

# Terminate instance
aws ec2 terminate-instances --instance-ids $INSTANCE_ID

# Monitor ASG (run in separate terminal)
watch -n 10 "aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $(terraform output -raw asg_name) \
  --query 'AutoScalingGroups[0].Instances[*].[InstanceId,LifecycleState,HealthStatus]' \
  --output table"
```

**Expected Timeline**:
- 0-1 min: Instance shows as "Terminating"
- 1-2 min: New instance shows as "Pending"
- 2-4 min: New instance shows as "InService"
- During this time, ALB continues serving from healthy instance

---

### TC5: CPU Stress and Scale-Out

```bash
# SSH to instance
ssh -A -i ~/.ssh/your-key.pem ec2-user@$(terraform output -raw bastion_public_ip)

# From bastion, SSH to app instance
ssh ec2-user@<private-ip>

# Run stress test (10 minutes)
stress-ng --cpu 2 --timeout 600
```

**Monitor CPU**:
```bash
# In separate terminal
watch -n 30 "aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=AutoScalingGroupName,Value=$(terraform output -raw asg_name) \
  --start-time \$(date -u -v-10M '+%Y-%m-%dT%H:%M:%SZ') \
  --end-time \$(date -u '+%Y-%m-%dT%H:%M:%SZ') \
  --period 60 --statistics Average \
  --query 'Datapoints[-1].Average'"
```

**Expected Timeline**:
- 0-5 min: CPU rises above 70%
- 5-10 min: Alarm triggers, email notification sent
- 10-15 min: New instance launched due to target tracking policy

---

### TC6: RDS Public Access Test

```bash
# Get RDS endpoint
RDS_HOST=$(terraform output -raw rds_address)

# Try to connect from local machine (should timeout)
mysql -h $RDS_HOST -u admin -p --connect-timeout=10
```

**Expected**: Connection timeout or "Host not allowed" error.

---

### TC7: SSH Access Path Test

```bash
# Step 1: Try direct SSH to private IP (should fail)
PRIVATE_IP="10.0.11.xxx"  # Get from curl output
ssh -i ~/.ssh/your-key.pem ec2-user@$PRIVATE_IP -o ConnectTimeout=10

# Step 2: SSH via bastion (should succeed)
ssh -A -i ~/.ssh/your-key.pem ec2-user@$(terraform output -raw bastion_public_ip)

# From bastion
ssh ec2-user@$PRIVATE_IP
```

**Expected**: 
- Direct connection fails (timeout or connection refused)
- Connection via bastion succeeds

---

### TC8: Health Check Failure Test

```bash
# SSH to instance via bastion
ssh -A -i ~/.ssh/your-key.pem ec2-user@$(terraform output -raw bastion_public_ip)
ssh ec2-user@<private-ip>

# Stop nginx
sudo systemctl stop nginx

# Monitor target group health
# (run from local machine, not the instance you stopped nginx on)
watch -n 10 "aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -json | jq -r '.security_groups.value.app') \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]' --output table"
```

**Expected Timeline**:
- 0-1 min: Instance shows as "healthy"
- 1-2 min: Instance shows as "unhealthy"
- 2-3 min: Unhealthy host alarm fires
- 3-6 min: ASG terminates unhealthy instance and launches replacement

---

## Screenshot Checklist

After completing tests, capture these screenshots:

| # | Screenshot | Description | Captured? |
|---|------------|-------------|-----------|
| 1 | `terraform-apply-success.png` | Successful `terraform apply` output showing all resources created | ⬜ |
| 2 | `web-page-az1.png` | Web page showing instance in AZ-1 | ⬜ |
| 3 | `web-page-az2.png` | Web page showing instance in AZ-2 (after refresh) | ⬜ |
| 4 | `db-route.png` | `/db` endpoint showing visit count | ⬜ |
| 5 | `vpc-resource-map.png` | AWS Console VPC resource map | ⬜ |
| 6 | `target-group-healthy.png` | Target group with 2 healthy targets | ⬜ |
| 7 | `asg-activity.png` | ASG activity history showing replacement | ⬜ |
| 8 | `cloudwatch-alarm.png` | CloudWatch alarm in ALARM state | ⬜ |
| 9 | `sns-email.png` | Email notification from SNS | ⬜ |
| 10 | `cloudwatch-dashboard.png` | CloudWatch dashboard with metrics | ⬜ |
| 11 | `security-groups.png` | Security groups showing inbound rules | ⬜ |
| 12 | `github-ci-passing.png` | GitHub Actions workflow passing | ⬜ |

---

## Notes

Add any observations or issues encountered during testing:

```
Date: 
Tester: R Koushik
Environment: dev

Notes:
- 
- 
- 
```
