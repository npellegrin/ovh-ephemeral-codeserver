.PHONY: bootstrap create destroy backup restore ssh-wait generate-ephemeral-vars

# group_vars/vault.yml is Ansible Vault-encrypted; this prompts for the vault
# password interactively. Override on the command line if needed.
VAULT_ARGS ?= --ask-vault-pass

EPHEMERAL_TFVARS := generated.tfvars

bootstrap:
	cd terraform-bootstrap && terraform init -input=false -backend-config=backend.tfvars
	cd terraform-bootstrap && terraform apply -input=false -var-file=terraform.tfvars

# Reads terraform-bootstrap's outputs into $(EPHEMERAL_TFVARS)
# Regenerated on every run, not committed
generate-ephemeral-vars:
	@echo "Reading terraform-bootstrap outputs into $(EPHEMERAL_TFVARS)..."
	@{ \
	  echo 'ovh_project_id = "'$$(cd terraform-bootstrap && terraform output -raw ovh_project_id)'"'; \
	  echo 'compute_region = "'$$(cd terraform-bootstrap && terraform output -raw compute_region)'"'; \
	  echo 'keypair_name   = "'$$(cd terraform-bootstrap && terraform output -raw keypair_name)'"'; \
	} > terraform-ephemeral/$(EPHEMERAL_TFVARS)

create: generate-ephemeral-vars
	cd terraform-ephemeral && terraform init -input=false -backend-config=backend.tfvars
	cd terraform-ephemeral && terraform apply -input=false -var-file=terraform.tfvars -var-file=$(EPHEMERAL_TFVARS)
	$(MAKE) ssh-wait
	cd ansible && ansible-playbook -i inventory/generated.ini site.yml $(VAULT_ARGS)
	cd ansible && ansible-playbook -i inventory/generated.ini restore.yml $(VAULT_ARGS)

destroy: generate-ephemeral-vars
	cd ansible && ansible-playbook -i inventory/generated.ini backup.yml $(VAULT_ARGS)
	cd terraform-ephemeral && terraform destroy -input=false -var-file=terraform.tfvars -var-file=$(EPHEMERAL_TFVARS)

backup:
	cd ansible && ansible-playbook -i inventory/generated.ini backup.yml $(VAULT_ARGS)

restore:
	cd ansible && ansible-playbook -i inventory/generated.ini restore.yml $(VAULT_ARGS)

ssh-wait:
	@echo "Waiting for SSH to become available..."
	@IP=$$(cd terraform-ephemeral && terraform output -raw public_ip); \
	until nc -z -w2 $$IP 22; do sleep 5; echo "Waiting for $$IP:22..."; done
	@sleep 10
