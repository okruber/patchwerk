# Terraform Best Practices

## Provider Versioning

**Always pin provider versions in `versions.tf` using pessimistic constraint operator (`~>`).**

```hcl
# versions.tf
terraform {
  required_version = "~> 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"    # Allows 5.x but not 6.0
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}
```

**Why pessimistic versioning (`~> 5.0`)?**
- Allows patch and minor updates (5.0.1, 5.1.0)
- Blocks breaking major version changes (6.0.0)
- Balances stability with security updates

**Avoid:**
- `>= 5.0` - Too permissive, allows breaking changes
- `= 5.0.0` - Too strict, blocks security patches
- No version constraint - Unpredictable builds

---

## Variables: Less is More

**Not everything needs to be a variable.** Over-parameterization creates complexity without benefit.

### Make it a variable when:
- Value differs between environments (dev/test/prod)
- Value is sensitive (secrets, keys)
- Value is likely to change independently of code
- Module is designed for reuse across projects

### Keep it hardcoded when:
- Value is stable infrastructure constant
- Value is tightly coupled to the module's purpose
- Changing it would require code changes anyway
- Only one valid value exists

**Example - Over-parameterized (bad):**
```hcl
variable "enable_versioning" {
  default = true  # Will always be true
}

variable "storage_class" {
  default = "STANDARD"  # Never changes
}

variable "location" {
  default = "US"  # Defined by compliance, won't change
}
```

**Example - Right-sized (good):**
```hcl
# Only parameterize what actually varies
variable "project_id" {}
variable "environment" {}

resource "google_storage_bucket" "data" {
  name          = "${var.project_id}-data-${var.environment}"
  location      = "US"           # Compliance requirement, hardcode it
  storage_class = "STANDARD"     # Always standard for this use case
  versioning {
    enabled = true               # Always enabled, hardcode it
  }
}
```

---

## Outputs: Only When Needed

**Don't create `outputs.tf` speculatively.** Only add outputs when:

1. Another module needs to reference the value
2. CI/CD pipeline needs the value
3. Human operators need to see the value after apply

**Signs you don't need outputs:**
- Module is a leaf node (nothing depends on it)
- Values are only used internally
- You're adding outputs "just in case"

---

## Module Organization

### Maximum 2 Levels Deep

```
# Good: 2 levels
modules/datalake/storage.tf
environments/dev/datalake/main.tf

# Bad: 3+ levels
modules/data/lake/storage/bucket.tf
```

Deep nesting creates:
- Complex relative paths
- Difficult state management
- Hard-to-follow dependencies

### Group by Infrastructure Layer or Feature

**By layer** (when infrastructure is shared):
```
modules/
├── database/      # All database resources
├── networking/    # VPC, subnets, firewall
├── storage/       # GCS buckets
└── compute/       # VMs, Cloud Run
```

**By feature** (when infrastructure is isolated):
```
modules/
├── datalake/      # BigQuery + GCS for analytics
├── dataflow/      # Dataflow jobs + associated resources
├── api-backend/   # Cloud Run + Load Balancer
└── etl-pipeline/  # Cloud Functions + Pub/Sub
```

---

## File Naming

**Name files by concept, not generic names.**

```
# Good: Clear purpose
database.tf         # Database resources
iam.tf              # IAM bindings
storage.tf          # Storage buckets
pubsub.tf           # Pub/Sub topics and subscriptions

# Bad: Generic names
main.tf             # What's in here?
resources.tf        # Too vague
misc.tf             # Catch-all antipattern
```

**Exception:** `main.tf` is appropriate in environment directories where it calls a module:
```hcl
# environments/dev/datalake/main.tf
module "datalake" {
  source = "../../../modules/datalake"

  project_id  = "my-project-dev"
  environment = "dev"
}
```

---

## Source Code in Modules

**When a module deploys code (Cloud Functions, Cloud Run, Lambda), keep source under the module:**

```
modules/
└── cloud-run-function/
    ├── function.tf
    ├── variables.tf
    ├── versions.tf
    └── src/
        ├── main.py
        ├── requirements.txt
        └── Dockerfile
```

**Benefits:**
- Single source of truth for infrastructure + code
- Changes are atomic (infra and code deploy together)
- Clear ownership and dependencies
- Easier to understand what a module does

**Avoid:**
- Separate repository for function code
- Code in a top-level `src/` directory
- Symlinks to code elsewhere
