# Observability Stack Template

Sets up Prometheus + Grafana + Alertmanager for a client.

## What It Deploys

| Component | Version | Purpose |
|---|---|---|
| Prometheus | v2.48.0 | Metrics collection and alerting |
| Grafana | v10.2.0 | Dashboards and visualization |
| Alertmanager | v0.26.0 | Alert routing (email + Slack) |
| Node Exporter | v1.7.0 | Host metrics (CPU, memory, disk) |
| Blackbox Exporter | v0.24.0 | HTTP endpoint monitoring |

## Deployment Options

- **Docker Compose** — single server, `docker compose up -d`
- **Helm** — Kubernetes, `helm install obs ./helm`

## Alert Rules Included

- CPU > 85% (warning), > 95% (critical)
- Memory > 85%
- Disk > 80% (warning), > 90% (critical)
- Instance down for > 1 minute
- HTTP 5xx error rate > 5%
- HTTP p99 latency > 2s
- Endpoint probe failure

## Phase

Phase 3 — Observability Stack.
