# 🔍 Weekly Dependency & Security Audit

**Repository:** demo-infra-terraform
**Date:** 2026-04-21
**Agent:** Oz Weekly Audit

## Summary

| Category | Issues Found | Severity |
|----------|--------------|----------|
| Outdated Dependencies | 1 | ⚠️ Medium |
| Known CVEs | 0 | ✅ None |
| Security Issues | 4 | 🔴 Critical |

## Outdated Dependencies

| Package | Current | Latest | Behind |
|---------|---------|--------|--------|
| hashicorp/aws provider | `~> 4.0` | `~> 5.x` | major |

The `~> 4.0` constraint is a full major release behind. AWS provider 5.x includes security and resource fixes and deprecates several v4 arguments (including the inline `acl` attribute on `aws_s3_bucket`).

## Known Vulnerabilities (CVEs)

No Terraform-core CVEs identified for the pinned provider range, but continuing to run on a major-version-behind provider delays access to upstream security fixes.

## Security Issues

| File | Line | Issue | Recommendation |
|------|------|-------|----------------|
| `main.tf` | 14-17 | 🔴 **Public-read S3 bucket** (`acl = "public-read"`). Any object written to `my-demo-bucket-oz-test` is world-readable. | Remove `acl = "public-read"`. Add `aws_s3_bucket_public_access_block` with all four flags = `true`, and manage ACLs via `aws_s3_bucket_acl` (private) if needed. |
| `main.tf` | 14-17 | 🔴 **No server-side encryption** configured on the S3 bucket. | Add `aws_s3_bucket_server_side_encryption_configuration` with `AES256` or KMS. |
| `variables.tf` | 1-3 | 🔴 **Hardcoded secret** — `db_password` default is `"supersecret123!"`. Committed to git history. | Remove the default. Source from a secrets manager (AWS Secrets Manager / SSM SecureString) or mark `sensitive = true` and inject via TF_VAR. Rotate the leaked value. |
| `variables.tf` | 5-7 | 🔴 **Hardcoded API key** — `api_key` default is `"sk-1234567890abcdef"`. | Remove the default, mark `sensitive = true`, and rotate the key. Load from secret store at runtime. |

Additional observations:
- Bucket has no `versioning` or `logging` configured.
- Provider version uses `~> 4.0`; upgrade to `~> 5.0` and refactor to the split-resource S3 pattern required by AWS provider 5.x.

## Recommendations

1. **Critical** (fix immediately):
   - Remove `acl = "public-read"` and add a `aws_s3_bucket_public_access_block` blocking all public access.
   - Remove hardcoded `db_password` and `api_key` defaults from `variables.tf`; rotate both secrets.
2. **High** (fix this sprint):
   - Enable S3 server-side encryption (AES256 or KMS).
   - Enable S3 versioning and access logging.
   - Upgrade AWS provider constraint to `~> 5.0` and migrate inline bucket config to the discrete resources (`aws_s3_bucket_acl`, `aws_s3_bucket_versioning`, etc.).
3. **Medium** (plan for next sprint):
   - Add `tfsec` / `checkov` to CI.
   - Introduce a remote state backend with encryption & locking (S3 + DynamoDB or Terraform Cloud).

## Notes / Tooling

- `tfsec` / `checkov` were not executed; findings above come from static review of `main.tf` and `variables.tf`.

---
*Generated automatically by Oz Weekly Audit Agent*
