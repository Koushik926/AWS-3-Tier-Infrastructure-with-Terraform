# Database Module

Creates an RDS MySQL instance with secure credential management via AWS Secrets Manager.

## Features

- RDS MySQL 8.0 with gp3 storage (encrypted)
- Secure password generation with `random_password`
- Credentials stored in AWS Secrets Manager
- Custom parameter group with UTF-8 support
- DB subnet group for isolation in private subnets
- Multi-AZ support (configurable)

## Security

- Database is in private subnets with no public access
- Credentials are never stored in Terraform state files directly
- Application retrieves credentials from Secrets Manager at runtime
- Storage encryption enabled by default

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| vpc_id | ID of the VPC | `string` | n/a | yes |
| subnet_ids | List of DB subnet IDs | `list(string)` | n/a | yes |
| security_group_id | ID of the DB security group | `string` | n/a | yes |
| instance_class | RDS instance class | `string` | `"db.t3.micro"` | no |
| allocated_storage | Storage in GB | `number` | `20` | no |
| db_name | Database name | `string` | `"appdb"` | no |
| db_username | Master username | `string` | `"admin"` | no |
| multi_az | Enable Multi-AZ | `bool` | `false` | no |
| backup_retention_period | Days to retain backups | `number` | `1` | no |
| engine_version | MySQL version | `string` | `"8.0"` | no |

## Outputs

| Name | Description |
|------|-------------|
| db_endpoint | Connection endpoint (host:port) |
| db_address | Hostname only |
| db_port | Port number |
| db_name | Database name |
| db_secret_arn | ARN of Secrets Manager secret |
| db_secret_name | Name of Secrets Manager secret |
| db_arn | ARN of RDS instance |

## Secret Structure

The Secrets Manager secret contains:

```json
{
  "username": "admin",
  "password": "<generated>",
  "host": "<rds-endpoint>",
  "port": 3306,
  "dbname": "appdb",
  "engine": "mysql"
}
```

## Cost Considerations

⚠️ **Free Tier eligible** with `db.t3.micro`:
- 750 hours/month of db.t3.micro (or db.t2.micro) 
- 20 GB of General Purpose (SSD) storage
- 20 GB of backup storage

Multi-AZ doubles the cost - keep `multi_az = false` for development.

## Connecting to the Database

From an app instance (via bastion or SSM):

```bash
# Install MySQL client
sudo dnf install -y mariadb105

# Get credentials from Secrets Manager
SECRET=$(aws secretsmanager get-secret-value \
  --secret-id <secret-arn> \
  --query SecretString \
  --output text)

# Parse and connect
DB_HOST=$(echo $SECRET | jq -r '.host')
DB_USER=$(echo $SECRET | jq -r '.username')
DB_PASS=$(echo $SECRET | jq -r '.password')
DB_NAME=$(echo $SECRET | jq -r '.dbname')

mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME
```
