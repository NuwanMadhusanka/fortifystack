# FortifyStack - convenience targets
# Usage: make <target>   (run from repo root)

ENV     ?= dev
TFDIR    = terraform/envs/$(ENV)
BOOTSTRAP= bootstrap

.PHONY: help bootstrap init plan apply destroy fmt validate output url dashboard clean

help:
	@echo "FortifyStack targets:"
	@echo "  make bootstrap   - create S3 state bucket + DynamoDB lock table (run once)"
	@echo "  make init        - terraform init for env ($(ENV))"
	@echo "  make plan        - terraform plan"
	@echo "  make apply       - terraform apply"
	@echo "  make destroy     - terraform destroy (tear everything down to stop costs)"
	@echo "  make fmt         - terraform fmt -recursive"
	@echo "  make validate    - terraform validate"
	@echo "  make output      - show terraform outputs"
	@echo "  make url         - print the app URL"

bootstrap:
	cd $(BOOTSTRAP) && terraform init && terraform apply

init:
	cd $(TFDIR) && terraform init

plan:
	cd $(TFDIR) && terraform plan

apply:
	cd $(TFDIR) && terraform apply

destroy:
	cd $(TFDIR) && terraform destroy

fmt:
	terraform fmt -recursive

validate:
	cd $(TFDIR) && terraform validate

output:
	cd $(TFDIR) && terraform output

url:
	cd $(TFDIR) && terraform output -raw app_url
