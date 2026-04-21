# 🔍 Weekly Dependency & Security Audit

**Repository:** demo-infra-terraform
**Date:** 2026-04-21
**Agent:** Oz Weekly Audit

## Summary

| Category | Issues Found | Severity |
|----------|--------------|----------|
| Outdated Dependencies (providers) | 1 | ⚠️ Medium |
| Known CVEs | 0 | ✅ None |
| Security Issues | 4 | 🔴 Critical |

## Outdated Dependencies

| Provider | Current Constraint | Latest | Behind |
|----------|--------------------|--------|--------|
| hashicorp/aws | `~> 4.0` | `6.41.0` | 2 major versions |

`~> 4.0` is a floating constraint in the 4.x line and is considered end-of-life for new features; the 6.x line is current. Migration will require addressing deprecations and the `aws_s3_bucket_*` resource split introduced in v4.

## Known Vulnerabilities (CVEs)

No direct CVEs are published against the pinned providers themselves, but the misconfigurations below are high-impact security issues.

## Security Issues

| File | Line | Issue | Recommendation |
|------|------|-------|----------------|
| `main.tf` | 16 | `aws_s3_bucket.demo` uses `acl = "public-read"` — bucket objects are world-readable. | Remove `acl`, use a dedicated `aws_s3_bucket_public_access_block` with all four flags set to `true`, and grant access via signed URLs / IAM / CloudFront OAC. |
| `main.tf` | 14-17 | `aws_s3_bucket.demo` has no server-side encryption, versioning, or access logging configured. | Add `aws_s3_bucket_server_side_encryption_configuration` (SSE-S3 or SSE-KMS), `aws_s3_bucket_versioning`, and `aws_s3_bucket_logging`. |
| `variables.tf` | 1-3 | `db_password` variable has a hardcoded default `"supersecret123!"` — a secret is committed to source. | Remove the `default`, mark `sensitive = true`, and source the value from AWS Secrets Manager / SSM Parameter Store / env. Rotate the leaked credential. |
| `variables.tf` | 5-7 | `api_key` variable has a hardcoded default `"sk-1234567890abcdef"` (OpenAI-style key format) committed to source. | Remove the `default`, mark `sensitive = true`, source from a secrets manager, and rotate the leaked key. |

All four issues were also flagged by a `grep` scan for `password|secret|api_key|token|private_key` across `*.tf`.

## Recommendations

1. **Critical (fix immediately)**
   - Rotate **any** credentials that match the committed defaults (`db_password`, `api_key`) — treat them as leaked, even if they are placeholders. If real, revoke at the provider.
   - Remove hardcoded `default` values from `variables.tf` for `db_password` and `api_key`; mark them `sensitive = true` and source from a secrets manager.
   - Remove `acl = "public-read"` from the S3 bucket and attach an `aws_s3_bucket_public_access_block` with all four flags enabled.
2. **High (this sprint)**
   - Add SSE encryption, versioning, and access logging to `aws_s3_bucket.demo`.
   - Plan upgrade of `hashicorp/aws` provider from `~> 4.0` → `~> 6.0` (addresses deprecations and the `aws_s3_bucket_*` resource split from v4).
3. **Medium (plan for next sprint)**
   - Add `tfsec` / `checkov` / `terrascan` to CI to catch these patterns automatically.
   - Add `terraform fmt` and `terraform validate` checks, and consider `terraform-docs` for variable hygiene.
   - Consider enabling [git-secrets](https://github.com/awslabs/git-secrets) or a pre-commit hook to block future secret commits.

***
*Generated automatically by Oz Weekly Audit Agent*
