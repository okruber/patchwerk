---
name: terraform
description: Terraform infrastructure-as-code standards with project-specific context loading. Use when writing, reviewing, or refactoring Terraform modules. Covers module organization, versioning, security scanning with Checkov, and automatic documentation generation.
---

# Terraform Infrastructure Standards

## CRITICAL: Load Project Context First

**Before writing ANY Terraform code**, you MUST check for and load project-specific configuration:

```
.claude/docs/project/terraform.md
```

This file contains project-specific Terraform implementation details including:
- Provider configurations and required versions
- Backend state configuration
- Project-specific naming conventions
- Environment-specific patterns (dev/staging/prod)
- Custom module locations
- CI/CD pipeline integration details

**If this file exists, read it completely before proceeding.** Project-specific instructions override general guidance below.

**If the file does not exist**, proceed with general best practices and consider creating it for the project.

---

## General Terraform Standards

@references/terraform-practices.md

## Module Structure Example

```
terraform/
├── modules/
│   ├── database/
│   │   ├── database.tf          # Main resource definitions
│   │   ├── variables.tf
│   │   ├── outputs.tf           # Only if outputs will be consumed
│   │   └── versions.tf          # Provider version constraints
│   ├── cloud-run-function/
│   │   ├── function.tf
│   │   ├── iam.tf
│   │   ├── variables.tf
│   │   ├── versions.tf
│   │   └── src/                  # Source code for the function
│   │       ├── main.py
│   │       └── requirements.txt
│   └── datalake/
│       ├── storage.tf
│       ├── bigquery.tf
│       └── versions.tf
├── environments/
│   ├── dev/
│   │   ├── datalake/            # Each module instantiated separately
│   │   │   └── main.tf          # Calls ../../modules/datalake
│   │   ├── database/
│   │   │   └── main.tf
│   │   └── cloud-run-function/
│   │       └── main.tf
│   ├── test/
│   │   ├── datalake/
│   │   │   └── main.tf
│   │   └── database/
│   │       └── main.tf
│   └── prod/
│       ├── datalake/
│       │   └── main.tf
│       ├── database/
│       │   └── main.tf
│       └── cloud-run-function/
│           └── main.tf
├── Makefile                      # Quality gates (fmt, checkov, docs)
└── README.md
```

## Quick Reference

| Principle | Do | Don't |
|-----------|-----|-------|
| **File naming** | Name by concept: `database.tf`, `iam.tf` | Generic `main.tf` everywhere |
| **Variables** | Only parameterize what varies | Make everything a variable |
| **Outputs** | Only when consumed downstream | Create empty `outputs.tf` |
| **Module depth** | Max 2 levels | Deeply nested modules |
| **Source code** | Under module: `modules/X/src/` | Scattered in separate repos |
| **Versioning** | Pessimistic: `~> 5.0` | Exact pins or floating |
