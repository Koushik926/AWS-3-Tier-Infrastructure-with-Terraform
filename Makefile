# =============================================================================
# AWS 3-Tier Infrastructure with Terraform - Makefile
# =============================================================================

.PHONY: help bootstrap init fmt validate lint plan apply destroy output clean

# Default target
help:
	@echo "AWS 3-Tier Infrastructure with Terraform"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Bootstrap (run once):"
	@echo "  bootstrap     Initialize and apply the bootstrap configuration (S3 + DynamoDB)"
	@echo ""
	@echo "Development:"
	@echo "  init          Initialize Terraform with backend configuration"
	@echo "  fmt           Format all Terraform files"
	@echo "  validate      Validate Terraform configuration"
	@echo "  lint          Run TFLint on all Terraform files"
	@echo "  plan          Generate and show execution plan"
	@echo "  apply         Apply the Terraform configuration"
	@echo "  destroy       Destroy all infrastructure"
	@echo "  output        Show Terraform outputs"
	@echo ""
	@echo "Utilities:"
	@echo "  clean         Remove .terraform directories and lock files"
	@echo "  check         Run fmt, validate, and lint"
	@echo ""
	@echo "Note: Set BUCKET, TABLE, and REGION environment variables for init:"
	@echo "  BUCKET=aws-3tier-dev-tfstate-123456789012 TABLE=aws-3tier-dev-tflock REGION=ap-south-1 make init"

# Variables
ENV_DIR := environments/dev
BOOTSTRAP_DIR := bootstrap

# =============================================================================
# Bootstrap Target
# =============================================================================

bootstrap:
	@echo "==> Initializing bootstrap configuration..."
	cd $(BOOTSTRAP_DIR) && terraform init
	@echo "==> Applying bootstrap configuration..."
	cd $(BOOTSTRAP_DIR) && terraform apply -auto-approve
	@echo ""
	@echo "Bootstrap complete! Note the outputs above for the init command."
	@echo ""
	@echo "Next steps:"
	@echo "1. Copy terraform.tfvars.example to terraform.tfvars:"
	@echo "   cd $(ENV_DIR) && cp terraform.tfvars.example terraform.tfvars"
	@echo ""
	@echo "2. Edit terraform.tfvars with your values"
	@echo ""
	@echo "3. Run init with the bucket and table from above:"
	@echo "   BUCKET=<bucket-name> TABLE=<table-name> REGION=ap-south-1 make init"

# =============================================================================
# Main Targets
# =============================================================================

init:
ifndef BUCKET
	$(error BUCKET is not set. Run: BUCKET=<bucket-name> TABLE=<table-name> REGION=<region> make init)
endif
ifndef TABLE
	$(error TABLE is not set. Run: BUCKET=<bucket-name> TABLE=<table-name> REGION=<region> make init)
endif
ifndef REGION
	$(error REGION is not set. Run: BUCKET=<bucket-name> TABLE=<table-name> REGION=<region> make init)
endif
	@echo "==> Initializing Terraform with backend configuration..."
	cd $(ENV_DIR) && terraform init \
		-backend-config="bucket=$(BUCKET)" \
		-backend-config="dynamodb_table=$(TABLE)" \
		-backend-config="region=$(REGION)"

fmt:
	@echo "==> Formatting Terraform files..."
	terraform fmt -recursive .
	@echo "Done!"

validate:
	@echo "==> Validating Terraform configuration..."
	cd $(ENV_DIR) && terraform validate
	@echo "Validation successful!"

lint:
	@echo "==> Running TFLint..."
	@if command -v tflint &> /dev/null; then \
		cd $(ENV_DIR) && tflint --recursive; \
		echo "TFLint complete!"; \
	else \
		echo "TFLint not installed. Install with: brew install tflint"; \
		exit 1; \
	fi

plan:
	@echo "==> Generating Terraform plan..."
	cd $(ENV_DIR) && terraform plan -out=tfplan
	@echo ""
	@echo "Plan saved to $(ENV_DIR)/tfplan"
	@echo "Run 'make apply' to apply this plan"

apply:
	@echo "==> Applying Terraform configuration..."
	@if [ -f "$(ENV_DIR)/tfplan" ]; then \
		cd $(ENV_DIR) && terraform apply tfplan && rm -f tfplan; \
	else \
		cd $(ENV_DIR) && terraform apply; \
	fi

destroy:
	@echo "==> WARNING: This will destroy all infrastructure!"
	@echo "==> Press Ctrl+C within 5 seconds to cancel..."
	@sleep 5
	cd $(ENV_DIR) && terraform destroy

output:
	@cd $(ENV_DIR) && terraform output

# =============================================================================
# Utility Targets
# =============================================================================

check: fmt validate lint
	@echo ""
	@echo "All checks passed!"

clean:
	@echo "==> Cleaning up Terraform files..."
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	find . -type f -name "tfplan" -delete 2>/dev/null || true
	@echo "Cleanup complete!"

# =============================================================================
# Quick Start
# =============================================================================

quickstart:
	@echo "AWS 3-Tier Infrastructure - Quick Start Guide"
	@echo "=============================================="
	@echo ""
	@echo "1. Bootstrap the state backend (one-time setup):"
	@echo "   make bootstrap"
	@echo ""
	@echo "2. Configure your variables:"
	@echo "   cd $(ENV_DIR)"
	@echo "   cp terraform.tfvars.example terraform.tfvars"
	@echo "   # Edit terraform.tfvars with your values"
	@echo ""
	@echo "3. Initialize Terraform (use outputs from step 1):"
	@echo "   BUCKET=<bucket-name> TABLE=<table-name> REGION=ap-south-1 make init"
	@echo ""
	@echo "4. Review the plan:"
	@echo "   make plan"
	@echo ""
	@echo "5. Apply the configuration:"
	@echo "   make apply"
	@echo ""
	@echo "6. When done, destroy everything:"
	@echo "   make destroy"
	@echo ""
	@echo "7. Optionally destroy the bootstrap resources:"
	@echo "   cd bootstrap && terraform destroy"
