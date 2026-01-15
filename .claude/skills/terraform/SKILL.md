---
name: terraform
description: Terraform infrastructure-as-code standards with project-specific context loading. Use when writing, reviewing, or refactoring Terraform modules. Covers module organization, versioning, security scanning with Checkov, and automatic documentation generation.
---

# Terraform Infrastructure Standards

## CRITICAL: Required Reading Before Any Terraform Work

**Before writing, reviewing, or refactoring ANY Terraform code**, you MUST read these files in order:

### 1. Terraform Best Practices (REQUIRED)

@references/terraform-practices.md

### 2. Project-Specific Context (if exists)

Check for and load project-specific configuration:

```
.claude/docs/project/terraform.md
```

This file contains project-specific implementation details including:
- Provider configurations and required versions
- Backend state configuration
- Project-specific naming conventions
- Environment-specific patterns (dev/staging/prod)
- Custom module locations
- CI/CD pipeline integration details

**If this file exists, read it completely.** Project-specific instructions override general guidance.

---

## General Terraform Standards

## Module Structure Example

```
terraform/
├── modules/
│   ├── database/
│   │   ├── database.tf          # Main resource definitions
│   │   ├── variables.tf
│   │   ├── outputs.tf           # Only if outputs will be consumed
│   │   └── versions.tf          # Provider version constraints
│   ├── cloud-run-job/
│   │   ├── job.tf               # Terraform resources
│   │   ├── iam.tf
│   │   ├── variables.tf
│   │   ├── versions.tf
│   │   ├── Dockerfile           # Container build (flat, not nested)
│   │   ├── pyproject.toml       # Dependencies
│   │   ├── src/                  # Python source code
│   │   │   └── main.py
│   │   └── tests/                # Tests
│   ├── airflow-pipeline/
│   │   ├── composer.tf          # Terraform resources
│   │   ├── variables.tf
│   │   ├── dags/                 # Airflow DAGs (conventional name)
│   │   │   └── my_dag.py
│   │   └── requirements.txt
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
│   │   └── cloud-run-job/
│   │       ├── main.tf
│   │       └── config/          # Environment-specific configs
│   │           └── config.yaml
│   └── prod/
│       ├── datalake/
│       │   └── main.tf
│       ├── database/
│       │   └── main.tf
│       └── cloud-run-job/
│           ├── main.tf
│           └── config/          # Prod-specific configs
│               └── config.yaml
├── Makefile                      # Quality gates (fmt, checkov, docs)
└── README.md
```

### Module Organization

**Keep source code WITH the module, but organized:**

| File Type | Location | Notes |
|-----------|----------|-------|
| Terraform (*.tf) | Module root | Infrastructure definitions |
| Dockerfile, pyproject.toml | Module root | Build/dependency files (flat) |
| Python source | `src/` | Conventional Python package location |
| Tests | `tests/` | Conventional test location |
| Airflow DAGs | `dags/` | Conventional Airflow location |
| dbt models | `models/` | Conventional dbt location |
| Environment configs | `environments/<env>/<svc>/config/` | NOT in modules |

**Key principle:** Use conventional folder names (`src/`, `dags/`, `models/`) for code, keep build files flat at module root.

## Quick Reference

| Principle | Do | Don't |
|-----------|-----|-------|
| **File naming** | Name by concept: `database.tf`, `iam.tf` | Generic `main.tf` everywhere |
| **Variables** | Only parameterize what varies | Make everything a variable |
| **Outputs** | Only when consumed downstream | Create empty `outputs.tf` |
| **Module depth** | Max 2 levels | Deeply nested modules |
| **Source code** | Flat in module with `src/`, `dags/` | Nested wrapper folders |
| **Env configs** | `environments/<env>/<svc>/config/` | Hardcoded in modules |
| **Versioning** | Pessimistic: `~> 5.0` | Exact pins or floating |
