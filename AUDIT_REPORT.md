# 🔍 Weekly Dependency & Security Audit

**Repository:** demo-infra-terraform
**Date:** 2026-04-20
**Agent:** Oz Weekly Audit

## Summary

| Category | Issues Found | Severity |
|----------|--------------|----------|
| Outdated Providers | 1 | ⚠️ Medium |
| Known CVEs | 0 | ✅ None |
| Security Issues | 5 | 🔴 Critical |

Tooling used: static analysis of `*.tf` (provider constraint check, `tfsec`-style patterns, secret scan).

## Outdated Providers

| Provider | Constraint | Latest | Behind |
|----------|-----------|--------|--------|
| hashicorp/aws | `~> 4.0` | 5.x / 6.x | major |

The `~> 4.0` pin locks the AWS provider to the 4.x line. AWS 4.x is no longer the primary supported line and misses new resources, argument fixes, and security-relevant updates (e.g. deprecated `aws_s3_bucket.acl` argument is properly handled in 5.x+ via `aws_s3_bucket_acl`).

## Known Vulnerabilities (CVEs)

No published CVEs affect the `hashicorp/aws` provider directly. The risks below are configuration-level.

## Security Issues

| File | Line | Severity | Issue | Recommendation |
|------|------|----------|-------|----------------|
| `variables.tf` | 1-3 | 🔴 Critical | Hardcoded `db_password` default (`supersecret123!`) committed to git | Remove default; mark `sensitive = true`; source from AWS Secrets Manager / SSM Parameter Store or TF_VAR env var |
| `variables.tf` | 5-7 | 🔴 Critical | Hardcoded `api_key` default (`sk-1234567890abcdef`) committed to git | Rotate the key **immediately**; remove default; mark `sensitive = true`; use a secrets backend |
| `main.tf`      | 14-17 | 🔴 Critical | S3 bucket `aws_s3_bucket.demo` configured with `acl = "public-read"` — anyone on the internet can list/read objects | Remove public ACL; add `aws_s3_bucket_public_access_block` with all four settings = `true` |
| `main.tf`      | 14-17 | 🟠 High | S3 bucket has no server-side encryption configured | Add `aws_s3_bucket_server_side_encryption_configuration` (AES256 or KMS) |
| `main.tf`      | 14-17 | 🟠 High | S3 bucket has no versioning or access logging | Add `aws_s3_bucket_versioning` and `aws_s3_bucket_logging` |

### Secret scan details

```
variables.tf:2:  default = "supersecret123!"
variables.tf:6:  default = "sk-1234567890abcdef"
```

Both values are committed to git history — even after the code is fixed, **credentials must be rotated** and history scrubbed if they were ever real.

### Terraform best-practice notes

- No `backend` configured → state is local, which can leak secrets. Use a remote backend (S3 + DynamoDB, Terraform Cloud, etc.) with encryption enabled.
- The deprecated inline `acl` argument on `aws_s3_bucket` is removed in AWS provider v4.0+ / split into `aws_s3_bucket_acl`. Using `~> 4.0` allows it but it is a code smell.

## Recommendations

1. **Critical (fix immediately):**
   - **Rotate** `db_password` and `api_key` at the upstream provider (database, API vendor).
   - Remove hardcoded defaults from `variables.tf`; flag variables as `sensitive = true`.
   - Remove `acl = "public-read"` and add a `aws_s3_bucket_public_access_block` resource blocking all public access.
2. **High (this sprint):**
   - Add S3 encryption, versioning, and access logging.
   - Configure a remote, encrypted Terraform backend.
   - Bump provider to `~> 5.0` and split the S3 configuration into the modern, dedicated resources.
3. **Medium (next sprint):**
   - Add `tfsec` / `checkov` to CI to catch these patterns automatically.
   - Add a `.gitignore` entry for `*.tfvars` and a pre-commit secret scanner (e.g. `gitleaks`).

### Example hardened snippet

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}

variable "api_key" {
  type      = string
  sensitive = true
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
  versioning_configuration { status = "Enabled" }
}
```

***
*Generated automatically by Oz Weekly Audit Agent*
