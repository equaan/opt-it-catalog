# Security Scan Template

Adds security scanning to a client repository.

## Scanners

| Scanner | What it scans | Schedule |
|---|---|---|
| Trivy | Containers, filesystem, IaC (Terraform) | Every push + daily |
| OWASP | Project dependencies vs NVD database | Every push to main + weekly |

## Phase

Phase 4 — Security + Containers.
