# 🔍 Weekly Dependency & Security Audit

**Repository:** bartoszc/demo-infra-terraform
**Date:** 2026-04-19
**Agent:** Oz Weekly Audit

## Summary

| Category | Issues Found | Severity |
|----------|--------------|----------|
| Outdated Dependencies | 1 | ⚠️ Medium |
| Known CVEs | 0 (provider-level) | ✅ None |
| Security Issues | 4 | 🔴 High |

## Outdated Dependencies

| Package | Current | Latest | Behind |
|---------|---------|--------|--------|
| `hashicorp/aws` provider | `~> 4.0` | `5.x` (latest `5.x` series on the Terraform Registry) | major |

The `aws` provider has been on the `5.x` line since mid-2023 and has received many resource additions and
breaking fixes (notably the full split of `aws_s3_bucket_*` resources). Staying on `~> 4.0` prevents access
to current `aws_s3_bucket_public_access_block`, `aws_s3_bucket_server_side_encryption_configuration`,
and other hardening resources in their recommended form.

## Known Vulnerabilities (CVEs)

No provider-level CVEs detected. However, the _resource configuration_ in this repo contains multiple
well-known insecure patterns (see below).

## Security Issues

| File | Line | Issue | Recommendation |
|------|------|-------|----------------|
| `main.tf` | 14-17 | `aws_s3_bucket.demo` uses the deprecated `acl = "public-read"` attribute, exposing bucket contents to the public internet (CWE-284 / AWS FTR `S3.2`). | Remove `acl`. Add an `aws_s3_bucket_public_access_block` with all four flags set to `true`, and grant access via IAM / bucket policy if needed. |
| `main.tf` | 14-17 | Bucket has no server-side encryption, no versioning, and no access logging. | Add `aws_s3_bucket_server_side_encryption_configuration` (AES256 or KMS), `aws_s3_bucket_versioning`, and `aws_s3_bucket_logging`. |
| `variables.tf` | 1-3 | `variable "db_password"` has a hardcoded `default = "supersecret123!"` (secret checked into VCS, CWE-798). | Remove the `default`, mark `sensitive = true`, and source the value from a secret manager (AWS SSM Parameter Store / Secrets Manager) or TF_VAR env vars. Rotate the leaked value. |
| `variables.tf` | 5-7 | `variable "api_key"` has a hardcoded `default = "sk-1234567890abcdef"` (secret checked into VCS, CWE-798). | Same as above: remove default, mark sensitive, rotate the key. |
| `main.tf` | 1-8 | `required_providers` pins `aws` to `~> 4.0`, blocking security fixes shipped in the `5.x` line. | Bump to `~> 5.60` (or the latest 5.x you can validate) and re-run `terraform init -upgrade`. |

### Detector output

Grep for hardcoded credentials in Terraform files:

```
variables.tf:2:  default = "supersecret123!"
variables.tf:6:  default = "sk-1234567890abcdef"
```

### Suggested hardened `main.tf` skeleton

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "demo" {
  bucket = "my-demo-bucket-oz-test"
}

resource "aws_s3_bucket_public_access_block" "demo" {
  bucket                  = aws_s3_bucket.demo.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
  bucket = aws_s3_bucket.demo.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "demo" {
  bucket = aws_s3_bucket.demo.id
  versioning_configuration {
    status = "Enabled"
  }
}
```

### Suggested hardened `variables.tf`

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}

variable "api_key" {
  type      = string
  sensitive = true
}
```

## Recommendations

1. **Critical (fix immediately):**
   - Remove the public-read ACL from `aws_s3_bucket.demo` and add an `aws_s3_bucket_public_access_block`.
   - Rotate `db_password` and `api_key` — treat the current values as compromised now that they are in git
     history. Purge them from history with `git filter-repo` / BFG and rotate upstream.
2. **High (fix this sprint):**
   - Move secrets out of `variables.tf` defaults into a secret store or `TF_VAR_*` env vars with
     `sensitive = true`.
   - Add encryption, versioning, and access logging to the S3 bucket.
3. **Medium (plan for next sprint):**
   - Bump the `aws` provider to `~> 5.60`.
   - Add a `tfsec` / `checkov` / `trivy config` job to CI so these patterns fail the pipeline.

***
_Generated automatically by Oz Weekly Audit Agent_
