# 🔍 Weekly Dependency & Security Audit

**Repository:** demo-infra-terraform
**Date:** 2026-04-19
**Agent:** Oz Weekly Audit

## Summary

| Category | Issues Found | Severity |
|----------|--------------|----------|
| Outdated Providers | 1 | ⚠️ Medium |
| Known CVEs | 0 | ✅ None |
| Security Issues | 4 | 🔴 High |

Tools used: manual static review of `*.tf` (no `tfsec`/`checkov` binaries present in this environment).

## Outdated Providers

| Provider | Current Constraint | Latest Major | Behind |
|----------|--------------------|--------------|--------|
| hashicorp/aws | `~> 4.0` | `6.x` | 2 major versions |

The `~> 4.0` pin blocks upgrade to AWS provider 5.x/6.x, which include:
- `aws_s3_bucket_acl` / `aws_s3_bucket_public_access_block` split (required since 4.9+)
- Improved default encryption behavior for S3
- Numerous security-relevant bug fixes

## Security Issues

| File | Line | Issue | Recommendation |
|------|------|-------|----------------|
| `main.tf` | 14–17 | `aws_s3_bucket.demo` uses inline `acl = "public-read"`, making the bucket world-readable. In AWS provider ≥4.9 the inline `acl` argument is also deprecated. | Remove the `acl` argument; use `aws_s3_bucket_public_access_block` with all four flags set to `true`, and a separate `aws_s3_bucket_acl` resource with `acl = "private"` if an ACL is required. |
| `main.tf` | 14–17 | S3 bucket has no server-side encryption configured. | Add `aws_s3_bucket_server_side_encryption_configuration` (AES256 or KMS). |
| `variables.tf` | 1–3 | `variable "db_password"` has a hardcoded default `"supersecret123!"` committed to VCS. | Remove the `default`, mark the variable `sensitive = true`, and source the value from Secrets Manager / SSM / a `TF_VAR_db_password` env var. |
| `variables.tf` | 5–7 | `variable "api_key"` has a hardcoded default `"sk-1234567890abcdef"` committed to VCS. | Same as above — remove the default, set `sensitive = true`, and source from a secret store. Rotate the key immediately if this value was ever real. |

### Other observations

- No `backend` block is configured → state is stored locally and likely unencrypted; multi-collaborator runs will diverge.
- No `terraform { required_version = ... }` constraint on the core binary itself.
- No logging / access-logging on the S3 bucket.
- `bucket` name is globally hardcoded (`"my-demo-bucket-oz-test"`) — collisions across environments are likely.

## Recommendations

1. **Critical** (fix immediately):
   - Rotate any real secrets that may have matched the committed defaults in `variables.tf` and scrub them from git history (`git filter-repo` / BFG).
   - Remove `acl = "public-read"` from `aws_s3_bucket.demo` and add an explicit `aws_s3_bucket_public_access_block` blocking all public access.
2. **High** (fix this sprint):
   - Remove hardcoded defaults from `db_password` and `api_key`; mark them `sensitive = true` and supply via environment or secret store.
   - Add server-side encryption to the S3 bucket (AES256 minimum).
   - Add a `terraform { required_version = ">= 1.6" }` block and a remote, encrypted backend (S3 + DynamoDB lock, or Terraform Cloud).
3. **Medium** (plan for next sprint):
   - Loosen the AWS provider constraint to `~> 5.0` or `~> 6.0` and run `terraform init -upgrade`.
   - Add `tfsec` / `checkov` to CI to catch these categories of issues automatically.
   - Parameterize the bucket name via a variable to avoid global naming collisions.

***
*Generated automatically by Oz Weekly Audit Agent*
