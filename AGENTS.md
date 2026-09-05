# AGENTS.md — Project root

This is an Infrastructure-as-Code project (Terraform + Ansible) for an
ephemeral OVH cloud dev environment.

## Sub-agents

This repo defines scoped AGENTS.md files per directory. When working inside
one of these subdirectories, its AGENTS.md takes precedence over this root
file for anything specific to that scope (but does not override the global
rules below, which always apply):

- `terraform-bootstrap/AGENTS.md`
- `terraform-ephemeral/AGENTS.md`
- `ansible/AGENTS.md`

Always check for and read the closest AGENTS.md to the file(s) you're editing
before making changes.

## Rules for AI agents working in this repo

- Be concise. Do not explain basic Terraform/Ansible/OVH concepts unless asked.
- Do not add features that were not explicitly requested.
- Prefer editing existing files over creating new ones.
- Do not read or open `.terraform/`, `terraform.tfstate*`, `.terraform.lock.hcl`,
  `*.retry`, or any other gitignored binary/generated file. Treat them as
  opaque and out of scope.
- Never print secrets (API keys, tokens, passwords) even if found in a file.
- Keep code in English, comments minimal and only where behavior is non-obvious.
- Every file (`.tf`, `.yml`) starts with a short header comment stating its
  purpose. Add a comment on an individual resource/task only where its
  behavior or intent isn't obvious from its name. Stay concise.
- Match existing style: HCL formatting via `terraform fmt` conventions,
  Ansible YAML with 2-space indent.
- Write direct, technical, casual prose (README, comments, commit messages).
  No em dash character ("—"); use a period, comma, or parentheses instead.
- When unsure about a design decision, ask instead of assuming — do not
  silently pick an option among several valid ones.
