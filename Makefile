.PHONY: bootstrap create destroy backup restore ssh-wait check-secret-perms generate-ephemeral-vars generate-vault-vars generate-swift-vars code-server-url code-server-password

# group_vars/vault.yml is Ansible Vault-encrypted
VAULT_ARGS ?= --vault-password-file $(CURDIR)/.vault_pass

EPHEMERAL_TFVARS := generated.tfvars
VARS_FILE := ansible/group_vars/vars.yml
VAULT_FILE := ansible/group_vars/vault.yml

# Reads one top-level scalar out of a flat group_vars file
H := \#
yaml_get = sed -n 's/^$(1):[[:space:]]*"\?\([^"$(H)]*[^"$(H) ]\)"\?.*/\1/p' $(2)
vault_code_server_password = ansible-vault view $(VAULT_ARGS) $(VAULT_FILE) | $(call yaml_get,code_server_password,-)

# .vault_pass decrypts vault.yml and .env holds the OVH/OpenStack/S3
# credentials, so either one being group- or world-readable defeats the vault.
check-secret-perms:
	@for f in $(CURDIR)/.vault_pass $(CURDIR)/.env; do \
	  test -f "$$f" || continue; \
	  test -z "$$(find "$$f" -perm /077)" || \
	    { echo "Error: $$f is group/other-readable. Run: chmod 600 $$f" >&2; exit 1; }; \
	done

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

# Injects terraform-bootstrap's Object Storage outputs into Ansible vars
generate-vault-vars: check-secret-perms
	@test -f $(VARS_FILE) || { echo "Error: $(VARS_FILE) not found. Run: cp ansible/group_vars/vars.yml.example $(VARS_FILE), fill it in, then retry."; exit 1; }
	@test -f $(VAULT_FILE) || { echo "Error: $(VAULT_FILE) not found. Run: cp ansible/group_vars/vault.yml.example $(VAULT_FILE), fill in the manual secrets, then retry."; exit 1; }
	@BUCKET=$$(cd terraform-bootstrap && terraform output -raw backup_bucket_name) && \
	SWIFT_REGION=$$(cd terraform-bootstrap && terraform output -raw swift_region) && \
	SWIFT_TENANT_ID=$$(cd terraform-bootstrap && terraform output -raw swift_tenant_id) && \
	sed -i \
	  -e "s|^backup_bucket:.*|backup_bucket: \"$$BUCKET\"|" \
	  -e "s|^swift_region:.*|swift_region: \"$$SWIFT_REGION\"|" \
	  -e "s|^swift_tenant_id:.*|swift_tenant_id: \"$$SWIFT_TENANT_ID\"|" \
	  $(VARS_FILE) && \
	PLAIN=$$(mktemp) && SCRIPT=$$(mktemp) && chmod 600 "$$PLAIN" "$$SCRIPT" && \
	trap 'rm -f "$$PLAIN" "$$SCRIPT"' EXIT INT TERM && \
	if head -n1 $(VAULT_FILE) | grep -q '^\$$ANSIBLE_VAULT'; then \
	  ansible-vault view $(VAULT_ARGS) $(VAULT_FILE) > "$$PLAIN"; \
	else \
	  cp $(VAULT_FILE) "$$PLAIN"; \
	fi && \
	NEW_PASS=$$(head -c32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c32) && \
	printf '%s\n' "s|^code_server_password:.*|code_server_password: \"$$NEW_PASS\"|" > "$$SCRIPT" && \
	sed -i -f "$$SCRIPT" "$$PLAIN" && \
	ansible-vault encrypt $(VAULT_ARGS) --output=$(VAULT_FILE) "$$PLAIN" && \
	echo "code_server_password set. View it with: ansible-vault view $(VAULT_ARGS) $(VAULT_FILE)"

# Injects terraform-ephemeral's backup-user credentials into Ansible vault.
generate-swift-vars: check-secret-perms
	@test -f $(VAULT_FILE) || { echo "Error: $(VAULT_FILE) not found. Run: cp ansible/group_vars/vault.yml.example $(VAULT_FILE), fill in the manual secrets, then retry."; exit 1; }
	@SWIFT_USER=$$(cd terraform-ephemeral && terraform output -raw swift_username) && \
	SWIFT_KEY=$$(cd terraform-ephemeral && terraform output -raw swift_password | sed -e 's/[|&\\]/\\&/g') && \
	PLAIN=$$(mktemp) && SCRIPT=$$(mktemp) && chmod 600 "$$PLAIN" "$$SCRIPT" && \
	trap 'rm -f "$$PLAIN" "$$SCRIPT"' EXIT INT TERM && \
	if head -n1 $(VAULT_FILE) | grep -q '^\$$ANSIBLE_VAULT'; then \
	  ansible-vault view $(VAULT_ARGS) $(VAULT_FILE) > "$$PLAIN"; \
	else \
	  cp $(VAULT_FILE) "$$PLAIN"; \
	fi && \
	printf '%s\n' \
	  "s|^swift_user:.*|swift_user: \"$$SWIFT_USER\"|" \
	  "s|^swift_key:.*|swift_key: \"$$SWIFT_KEY\"|" > "$$SCRIPT" && \
	sed -i -f "$$SCRIPT" "$$PLAIN" && \
	ansible-vault encrypt $(VAULT_ARGS) --output=$(VAULT_FILE) "$$PLAIN"

create: generate-ephemeral-vars generate-vault-vars
	cd terraform-ephemeral && terraform init -input=false -backend-config=backend.tfvars
	cd terraform-ephemeral && terraform apply -input=false -var-file=terraform.tfvars -var-file=$(EPHEMERAL_TFVARS)
	$(MAKE) generate-swift-vars
	$(MAKE) ssh-wait
	@if [ "$$(cd terraform-ephemeral && terraform output -raw dns_managed)" != "true" ]; then \
	  IP4=$$(cd terraform-ephemeral && terraform output -raw public_ipv4); \
	  IP6=$$(cd terraform-ephemeral && terraform output -raw public_ipv6); \
	  echo "DNS is not managed by Terraform. Point your records now:"; \
	  [ -n "$$IP4" ] && echo "  A    -> $$IP4"; \
	  [ -n "$$IP6" ] && echo "  AAAA -> $$IP6"; \
	  echo "otherwise Let's Encrypt will fail in the next step."; \
	  read -p "Press enter to continue once DNS is set... " REPLY; \
	fi
	cd ansible && ansible-playbook -i inventory/generated.ini site.yml $(VAULT_ARGS)
	cd ansible && ansible-playbook -i inventory/generated.ini restore.yml $(VAULT_ARGS)

# The backup runs before the destroy, while the backup user still exists.
destroy: generate-ephemeral-vars generate-vault-vars generate-swift-vars
	cd ansible && ansible-playbook -i inventory/generated.ini backup.yml $(VAULT_ARGS)
	cd terraform-ephemeral && terraform destroy -input=false -var-file=terraform.tfvars -var-file=$(EPHEMERAL_TFVARS)

backup: generate-vault-vars generate-swift-vars
	cd ansible && ansible-playbook -i inventory/generated.ini backup.yml $(VAULT_ARGS)

restore: generate-vault-vars generate-swift-vars
	cd ansible && ansible-playbook -i inventory/generated.ini restore.yml $(VAULT_ARGS)

# Post-deploy access helpers. Both print a bare value on stdout and their
# errors on stderr, so `make -s` output can be piped or substituted.
code-server-url:
	@test -f $(VARS_FILE) || { echo "Error: $(VARS_FILE) not found." >&2; exit 1; }
	@DOMAIN=$$($(call yaml_get,domain_name,$(VARS_FILE))); \
	test -n "$$DOMAIN" || { echo "Error: no domain_name in $(VARS_FILE)." >&2; exit 1; }; \
	echo "https://$$DOMAIN/"

code-server-password:
	@test -f $(VAULT_FILE) || { echo "Error: $(VAULT_FILE) not found." >&2; exit 1; }
	@PASS=$$($(vault_code_server_password)); \
	test -n "$$PASS" || { echo "Error: no code_server_password in $(VAULT_FILE). Run: make generate-vault-vars" >&2; exit 1; }; \
	echo "$$PASS"

ssh-wait:
	@echo "Waiting for SSH to become available..."
	@IP4=$$(cd terraform-ephemeral && terraform output -raw public_ipv4); \
	until nc -z -w2 $$IP4 22; do sleep 5; echo "Waiting for $$IP4:22..."; done
	@sleep 10
