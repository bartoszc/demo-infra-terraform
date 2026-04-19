# 🔍 Weekly Dependency & Security Audit

**Repository:** demo-infra-terraform
**Date:** 2026-04-19
**Agent:** Oz Weekly Audit

## Summary

| Category | Issues Found | Severity |
|----------|-------------|----------|
| Outdated Dependencies | 1 | ⚠️ Medium |
| Known CVEs | 0 | ✅ None |
| Security Issues | 4 | 🔴 Critical |

## Outdated Dependencies

| Package | Current | Latest | Behind |
|---------|---------|--------|--------|
| hashicorp/aws provider | ~> 4.0 | 5.x | major |

The `aws` provider is pinned to the 4.x major line. Version 5.x has been GA for a
while and introduces important breaking changes (notably to S3 bucket resources,
which are directly relevant to this repo — see security issues below).

## Known Vulnerabilities (CVEs)

No CVEs known for the pinned provider version itself. However, the resource
configuration contains several critical misconfigurations (see next section).

## Security Issues

| File | Line | Issue | Recommendation |
|------|------|-------|----------------|
| `main.tf` | 14-17 | `aws_s3_bucket.demo` uses `acl = "public-read"` — bucket is world-readable. | Remove the public ACL. Use `aws_s3_bucket_public_access_block` to enforce `block_public_acls = true` and `restrict_public_buckets = true`. |
| `main.tf` | 14-17 | S3 bucket has no server-side encryption configured. | Add `aws_s3_bucket_server_side_encryption_configuration` with `AES256` or KMS. |
| `variables.tf` | 1-3 | `db_password` variable has a hardcoded default (`"supersecret123!"`) — secret committed to VCS. | Remove the `default`, mark the variable `sensitive = true`, and source the value from AWS Secrets Manager / SSM Parameter Store / env vars. Rotate the password since it has been exposed. |
| `variables.tf` | 5-7 | `api_key` variable has a hardcoded default (`"sk-1234567890abcdef"`) — looks like an API key committed to VCS. | Remove the `default`, mark `sensitive = true`, and source from a secret manager. Rotate the key immediately. |

## Additional Hardening Suggestions

- Add `aws_s3_bucket_versioning` and `aws_s3_bucket_logging` for the S3 bucket.
- Enable bucket ownership controls (`aws_s3_bucket_ownership_controls`) to
  disable ACLs entirely, which is the modern AWS best practice.
- Add `tfsec` / `checkov` / `trivy config` to CI to catch these issues automatically.
- Pin Terraform core version via `required_version` in the `terraform {}` block.

## Recommendations

1. **Critical** (fix immediately):
   - Rotate the exposed `db_password` and `api_key` values — treat them as compromised.
   - Remove hardcoded secret defaults from `variables.tf`.
   - Remove `acl = "public-read"` from `aws_s3_bucket.demo` unless the bucket is
     genuinely intended to serve public content (and even then, prefer a CloudFront
     + OAC pattern).
2. **High** (fix this sprint):
   - Add server-side encryption to the S3 bucket.
   - Add a `aws_s3_bucket_public_access_block` resource.
3. **Medium** (plan for next sprint):
   - Upgrade the AWS provider to `~> 5.0` and migrate S3 resources to the split
     resource model (`aws_s3_bucket_acl`, etc.).
   - Add static analysis (tfsec / checkov) to CI.

***
*Generated automatically by Oz Weekly Audit Agent*
