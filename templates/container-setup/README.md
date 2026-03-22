# Container Setup Template

Containerizes a client application with Dockerfile, Docker Compose, Kubernetes manifests, and Helm chart.

## Languages Supported

| Language | Base Image | Build Tool |
|---|---|---|
| Node.js | node:XX-alpine | npm |
| Python | python:XX-slim | pip + venv |
| Java | eclipse-temurin:XX | Maven |
| Go | golang:XX-alpine → distroless | go build |

## What Gets Generated

- Multi-stage Dockerfile — minimal production image, non-root user
- Docker Compose — local dev stack with optional DB and Redis
- Kubernetes manifests — Namespace, Deployment, Service, Ingress, HPA, ConfigMap, Secret
- Helm chart — wraps the K8s manifests with configurable values

## Phase

Phase 4 — Security + Containers.
