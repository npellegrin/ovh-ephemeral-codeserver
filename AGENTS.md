# AGENTS.md — Project root

Infrastructure-as-Code (Terraform + Ansible) for an ephemeral OVH cloud
dev environment.

## Sub-agents

Scoped AGENTS.md files per directory. When working in one, it takes
precedence for its scope but does not override the global rules below:

- `terraform-bootstrap/AGENTS.md`
- `terraform-ephemeral/AGENTS.md`
- `ansible/AGENTS.md`

Read the closest AGENTS.md before editing.

## Global rules

- Be concise. Don't explain basic Terraform/Ansible/OVH concepts unless
  asked.
- Don't add features that weren't explicitly requested.
- Prefer editing existing files over creating new ones.
- Don't read or open `.terraform/`, `terraform.tfstate*`,
  `.terraform.lock.hcl`, `*.retry`, or other gitignored/generated files.
  Treat them as opaque and out of scope.
- Never print secrets, even if found in a file.
- Code in English. Comments minimal, only where behavior is non-obvious.
- Every `.tf` / `.yml` file starts with a short header comment stating its
  purpose. Comment a resource/task only where intent isn't obvious from
  its name.
- Match existing style: `terraform fmt` for HCL, 2-space indent for
  Ansible YAML.
- Prose (README, comments, commits): direct, technical, casual. No em dash
  character ("—"); use a period, comma, or parentheses.
- When unsure about a design decision, ask. Don't silently pick among
  valid options.
