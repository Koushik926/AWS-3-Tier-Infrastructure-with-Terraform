# Backend configuration for remote state storage
#
# IMPORTANT: The S3 bucket and DynamoDB table must be created first by running:
#   cd bootstrap && terraform init && terraform apply
#
# Then initialize this environment with backend configuration:
#   terraform init \
#     -backend-config="bucket=<your-bucket-name>" \
#     -backend-config="dynamodb_table=<your-lock-table>" \
#     -backend-config="region=ap-south-1"
#
# Example:
#   terraform init \
#     -backend-config="bucket=aws-3tier-dev-tfstate-123456789012" \
#     -backend-config="dynamodb_table=aws-3tier-dev-tflock" \
#     -backend-config="region=ap-south-1"

terraform {
  backend "s3" {
    key     = "dev/terraform.tfstate"
    encrypt = true
  }
}
