.PHONY: bootstrap create destroy backup restore ssh-wait generate-ephemeral-vars generate-vault-vars

# group_vars/vault.yml is Ansible Vault-encrypted; .vault_pass (gitignored)
# holds the password so generate-vault-vars + every ansible-playbook call
# don't prompt repeatedly. Override on the command line if needed, e.g.
# `make create VAULT_ARGS=--ask-vault-pass`.
VAULT_ARGS ?= --vault-password-file $(CURDIR)/.vault_pass

EPHEMERAL_TFVARS := generated.tfvars
VARS_FILE := ansible/group_vars/vars.yml
VAULT_FILE := ansible/group_vars/vault.yml

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

# Injects terraform-bootstrap's S3 outputs.
generate-vault-vars:
	@test -f $(VARS_FILE) || { echo "Error: $(VARS_FILE) not found. Run: cp ansible/group_vars/vars.yml.example $(VARS_FILE), fill it in, then retry."; exit 1; }
	@test -f $(VAULT_FILE) || { echo "Error: $(VAULT_FILE) not found. Run: cp ansible/group_vars/vault.yml.example $(VAULT_FILE), fill in the manual secrets, then retry."; exit 1; }
	@S3_BUCKET=$$(cd terraform-bootstrap && terraform output -raw s3_bucket_name) && \
	S3_ENDPOINT=$$(cd terraform-bootstrap && terraform output -raw backup_s3_endpoint) && \
	S3_ACCESS_KEY=$$(cd terraform-bootstrap && terraform output -raw backup_s3_access_key) && \
	S3_SECRET_KEY=$$(cd terraform-bootstrap && terraform output -raw backup_s3_secret_key) && \
	sed -i \
	  -e "s|^s3_bucket:.*|s3_bucket: \"$$S3_BUCKET\"|" \
	  -e "s|^s3_endpoint:.*|s3_endpoint: \"$$S3_ENDPOINT\"|" \
	  $(VARS_FILE) && \
	(ansible-vault view $(VAULT_ARGS) $(VAULT_FILE) > /tmp/vault_plain.yml 2>/dev/null || cp $(VAULT_FILE) /tmp/vault_plain.yml) && \
	NEW_PASS=$$(head -c32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c32) && \
	sed -i \
	  -e "s|^s3_access_key:.*|s3_access_key: \"$$S3_ACCESS_KEY\"|" \
	  -e "s|^s3_secret_key:.*|s3_secret_key: \"$$S3_SECRET_KEY\"|" \
	  -e "s|^code_server_password:.*|code_server_password: \"$$NEW_PASS\"|" \
	  /tmp/vault_plain.yml && \
	ansible-vault encrypt $(VAULT_ARGS) --output=$(VAULT_FILE) /tmp/vault_plain.yml && \
	rm -f /tmp/vault_plain.yml && \
	echo "code_server_password set. View it with: ansible-vault view $(VAULT_ARGS) $(VAULT_FILE)"

create: generate-ephemeral-vars generate-vault-vars
	cd terraform-ephemeral && terraform init -input=false -backend-config=backend.tfvars
	cd terraform-ephemeral && terraform apply -input=false -var-file=terraform.tfvars -var-file=$(EPHEMERAL_TFVARS)
	$(MAKE) ssh-wait
	@if [ "$$(cd terraform-ephemeral && terraform output -raw dns_managed)" != "true" ]; then \
	  IP=$$(cd terraform-ephemeral && terraform output -raw public_ip); \
	  echo "DNS is not managed by Terraform. Point your A record at $$IP now,"; \
	  echo "otherwise Let's Encrypt will fail in the next step."; \
	  read -p "Press enter to continue once DNS is set... " REPLY; \
	fi
	cd ansible && ansible-playbook -i inventory/generated.ini site.yml $(VAULT_ARGS)
	cd ansible && ansible-playbook -i inventory/generated.ini restore.yml $(VAULT_ARGS)

destroy: generate-ephemeral-vars generate-vault-vars
	cd ansible && ansible-playbook -i inventory/generated.ini backup.yml $(VAULT_ARGS)
	cd terraform-ephemeral && terraform destroy -input=false -var-file=terraform.tfvars -var-file=$(EPHEMERAL_TFVARS)

backup: generate-vault-vars
	cd ansible && ansible-playbook -i inventory/generated.ini backup.yml $(VAULT_ARGS)

restore: generate-vault-vars
	cd ansible && ansible-playbook -i inventory/generated.ini restore.yml $(VAULT_ARGS)

ssh-wait:
	@echo "Waiting for SSH to become available..."
	@IP=$$(cd terraform-ephemeral && terraform output -raw public_ip); \
	until nc -z -w2 $$IP 22; do sleep 5; echo "Waiting for $$IP:22..."; done
	@sleep 10
