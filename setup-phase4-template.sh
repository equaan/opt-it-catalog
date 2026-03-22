#!/bin/bash
# ================================================================
# Opt IT — Phase 4 Templates Setup
# Run from inside your opt-it-catalog directory:
#   cd opt-it-catalog
#   bash setup-phase4-templates.sh
# ================================================================

set -e

echo "================================================================"
echo "  Opt IT — Creating Phase 4 Templates"
echo "================================================================"

mkdir -p templates/security-scan/skeleton/security/trivy
mkdir -p templates/security-scan/skeleton/security/owasp
mkdir -p templates/security-scan/skeleton/.github/workflows

mkdir -p templates/container-setup/skeleton/containers/dockerfiles
mkdir -p templates/container-setup/skeleton/containers/docker-compose
mkdir -p templates/container-setup/skeleton/containers/kubernetes/base
mkdir -p templates/container-setup/skeleton/containers/helm/templates

# ════════════════════════════════════════════════════════════════
# SECURITY SCAN TEMPLATE
# ════════════════════════════════════════════════════════════════

cat > templates/security-scan/catalog-info.yaml << 'EOF'
apiVersion: backstage.io/v1alpha1
kind: Location
metadata:
  name: security-scan-template
  description: Opt IT Security Scan Template
spec:
  targets:
    - ./template.yaml
EOF

cat > templates/security-scan/template.yaml << 'EOF'
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: security-scan
  title: Security Scan Setup
  description: Adds Trivy container/IaC scanning and OWASP dependency checking to a client repository.
  tags:
    - security
    - trivy
    - owasp
    - phase-4
spec:
  owner: devops
  type: security

  parameters:

    - title: Step 1 - Client Information
      required:
        - client_name
        - environment
        - repoUrl
      properties:
        client_name:
          title: Client Name
          type: string
          description: "Lowercase alphanumeric and hyphens only. Example: acme-corp"
          ui:autofocus: true

        environment:
          title: Environment
          type: string
          enum: [dev, staging, prod]
          enumNames: [Development, Staging, Production]
          ui:widget: radio

        repoUrl:
          title: Client Repository
          type: string
          ui:field: RepoUrlPicker
          ui:options:
            allowedHosts:
              - github.com

    - title: Step 2 - Security Configuration
      required:
        - security_config
      properties:
        security_config:
          title: Security Configuration
          type: object
          description: Configure security scanners for this repository
          ui:field: SecurityPicker
          ui:options:
            environment: ${{ parameters.environment }}

  steps:

    - id: fetch-trivy
      name: Fetch Trivy Configuration
      if: ${{ parameters.security_config.config.enable_trivy }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/security/trivy
        targetPath: ./security/trivy
        values:
          client_name:             ${{ parameters.client_name }}
          environment:             ${{ parameters.environment }}
          trivy_exit_code:         ${{ parameters.security_config.config.trivy_exit_code }}
          ignore_unfixed:          ${{ parameters.security_config.config.ignore_unfixed }}
          include_medium_severity: ${{ parameters.security_config.config.include_medium_severity }}
          scan_docker_image:       ${{ parameters.security_config.config.scan_docker_image }}
          scan_iac:                ${{ parameters.security_config.config.scan_iac }}

    - id: fetch-trivy-workflow
      name: Fetch Trivy GitHub Actions Workflow
      if: ${{ parameters.security_config.config.enable_trivy }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/security/github-actions
        targetPath: ./.github/workflows
        values:
          client_name:             ${{ parameters.client_name }}
          environment:             ${{ parameters.environment }}
          trivy_exit_code:         ${{ parameters.security_config.config.trivy_exit_code }}
          ignore_unfixed:          ${{ parameters.security_config.config.ignore_unfixed }}
          include_medium_severity: ${{ parameters.security_config.config.include_medium_severity }}
          scan_docker_image:       ${{ parameters.security_config.config.scan_docker_image }}
          scan_iac:                ${{ parameters.security_config.config.scan_iac }}

    - id: fetch-owasp
      name: Fetch OWASP Dependency Check
      if: ${{ parameters.security_config.config.enable_owasp }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/security/owasp
        targetPath: ./.github/workflows
        values:
          client_name:      ${{ parameters.client_name }}
          environment:      ${{ parameters.environment }}
          owasp_fail_cvss:  ${{ parameters.security_config.config.owasp_fail_cvss }}

    - id: publish-pr
      name: Open Pull Request on Client Repository
      action: publish:github:pull-request
      input:
        repoUrl: ${{ parameters.repoUrl }}
        branchName: security/${{ parameters.client_name }}-${{ parameters.environment }}-setup
        targetBranchName: main
        update: true
        title: "feat(security): add security scanning for ${{ parameters.client_name }}"
        description: |
          ## Security Scan Setup 🔒

          Provisioned by **Opt IT Backstage**.

          ### Scanners Added

          | Scanner | Status |
          |---|---|
          | Trivy | ${{ parameters.security_config.config.enable_trivy and '✅ Enabled' or '❌ Not selected' }} |
          | OWASP Dependency Check | ${{ parameters.security_config.config.enable_owasp and '✅ Enabled' or '❌ Not selected' }} |

          ### Next Steps

          1. Merge this PR
          2. Go to **Settings → Security → Code scanning** to view scan results
          3. Go to **Actions** to see scan workflow runs
          4. Review any findings in the **Security** tab

          > ⚠️ Enable GitHub Advanced Security on the repo to see SARIF results in the Security tab.

  output:
    links:
      - title: View Pull Request
        url: ${{ steps['publish-pr'].output.remoteUrl }}
EOF

cat > templates/security-scan/README.md << 'EOF'
# Security Scan Template

Adds security scanning to a client repository.

## Scanners

| Scanner | What it scans | Schedule |
|---|---|---|
| Trivy | Containers, filesystem, IaC (Terraform) | Every push + daily |
| OWASP | Project dependencies vs NVD database | Every push to main + weekly |

## Phase

Phase 4 — Security + Containers.
EOF

echo "✅ Security Scan template created"

# ════════════════════════════════════════════════════════════════
# CONTAINER SETUP TEMPLATE
# ════════════════════════════════════════════════════════════════

cat > templates/container-setup/catalog-info.yaml << 'EOF'
apiVersion: backstage.io/v1alpha1
kind: Location
metadata:
  name: container-setup-template
  description: Opt IT Container Setup Template
spec:
  targets:
    - ./template.yaml
EOF

cat > templates/container-setup/template.yaml << 'EOF'
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: container-setup
  title: Container Setup
  description: Containerizes a client application with Dockerfile, Docker Compose, Kubernetes manifests, and Helm chart.
  tags:
    - docker
    - kubernetes
    - helm
    - containers
    - phase-4
spec:
  owner: devops
  type: infrastructure

  parameters:

    - title: Step 1 - Client Information
      required:
        - client_name
        - environment
        - repoUrl
      properties:
        client_name:
          title: Client Name
          type: string
          description: "Lowercase alphanumeric and hyphens only. Example: acme-corp"
          ui:autofocus: true

        environment:
          title: Environment
          type: string
          enum: [dev, staging, prod]
          enumNames: [Development, Staging, Production]
          ui:widget: radio

        repoUrl:
          title: Client Repository
          type: string
          ui:field: RepoUrlPicker
          ui:options:
            allowedHosts:
              - github.com

    - title: Step 2 - Container Configuration
      required:
        - container_config
      properties:
        container_config:
          title: Container Configuration
          type: object
          description: Configure language, runtime, Docker Compose, Kubernetes, and Helm
          ui:field: ContainerPicker
          ui:options:
            environment: ${{ parameters.environment }}

  steps:

    - id: fetch-dockerfile
      name: Fetch Dockerfile
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/containers/dockerfiles
        targetPath: ./
        values:
          client_name:       ${{ parameters.client_name }}
          environment:       ${{ parameters.environment }}
          language:          ${{ parameters.container_config.config.language }}
          runtime_version:   ${{ parameters.container_config.config.runtime_version }}
          app_port:          ${{ parameters.container_config.config.app_port }}
          health_check_path: ${{ parameters.container_config.config.health_check_path }}

    - id: fetch-docker-compose
      name: Fetch Docker Compose
      if: ${{ parameters.container_config.config.include_docker_compose }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/containers/docker-compose
        targetPath: ./containers/docker-compose
        values:
          client_name:       ${{ parameters.client_name }}
          environment:       ${{ parameters.environment }}
          language:          ${{ parameters.container_config.config.language }}
          app_port:          ${{ parameters.container_config.config.app_port }}
          include_database:  ${{ parameters.container_config.config.include_database }}
          db_engine:         ${{ parameters.container_config.config.db_engine }}
          db_name:           ${{ parameters.container_config.config.db_name }}
          db_user:           ${{ parameters.container_config.config.db_user }}
          db_connection_string: "postgresql://${{ parameters.container_config.config.db_user }}:password@db:5432/${{ parameters.container_config.config.db_name }}"
          include_redis:     ${{ parameters.container_config.config.include_redis }}

    - id: fetch-kubernetes
      name: Fetch Kubernetes Manifests
      if: ${{ parameters.container_config.config.include_kubernetes }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/containers/kubernetes/base
        targetPath: ./containers/kubernetes
        values:
          client_name:            ${{ parameters.client_name }}
          environment:            ${{ parameters.environment }}
          k8s_namespace:          ${{ parameters.container_config.config.k8s_namespace }}
          container_registry:     ${{ parameters.container_config.config.container_registry }}
          domain:                 ${{ parameters.container_config.config.domain }}
          app_port:               ${{ parameters.container_config.config.app_port }}
          health_check_path:      ${{ parameters.container_config.config.health_check_path }}
          initial_replicas:       ${{ parameters.container_config.config.initial_replicas }}
          min_replicas:           ${{ parameters.container_config.config.min_replicas }}
          max_replicas:           ${{ parameters.container_config.config.max_replicas }}
          cpu_request:            ${{ parameters.container_config.config.cpu_request }}
          memory_request:         ${{ parameters.container_config.config.memory_request }}
          cpu_limit:              ${{ parameters.container_config.config.cpu_limit }}
          memory_limit:           ${{ parameters.container_config.config.memory_limit }}
          cpu_target_utilization: ${{ parameters.container_config.config.cpu_target_utilization }}

    - id: fetch-helm
      name: Fetch Helm Chart
      if: ${{ parameters.container_config.config.include_helm }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/containers/helm
        targetPath: ./containers/helm
        values:
          client_name:            ${{ parameters.client_name }}
          environment:            ${{ parameters.environment }}
          container_registry:     ${{ parameters.container_config.config.container_registry }}
          domain:                 ${{ parameters.container_config.config.domain }}
          app_port:               ${{ parameters.container_config.config.app_port }}
          health_check_path:      ${{ parameters.container_config.config.health_check_path }}
          k8s_namespace:          ${{ parameters.container_config.config.k8s_namespace }}
          initial_replicas:       ${{ parameters.container_config.config.initial_replicas }}
          min_replicas:           ${{ parameters.container_config.config.min_replicas }}
          max_replicas:           ${{ parameters.container_config.config.max_replicas }}
          cpu_request:            ${{ parameters.container_config.config.cpu_request }}
          memory_request:         ${{ parameters.container_config.config.memory_request }}
          cpu_limit:              ${{ parameters.container_config.config.cpu_limit }}
          memory_limit:           ${{ parameters.container_config.config.memory_limit }}
          cpu_target_utilization: ${{ parameters.container_config.config.cpu_target_utilization }}

    - id: publish-pr
      name: Open Pull Request on Client Repository
      action: publish:github:pull-request
      input:
        repoUrl: ${{ parameters.repoUrl }}
        branchName: containers/${{ parameters.client_name }}-${{ parameters.environment }}-${{ parameters.container_config.config.language }}
        targetBranchName: main
        update: true
        title: "feat(containers): add ${{ parameters.container_config.config.language }} container setup for ${{ parameters.client_name }}"
        description: |
          ## Container Setup 🐳

          Provisioned by **Opt IT Backstage**.

          ### What Was Generated

          | Component | Status |
          |---|---|
          | Dockerfile (${{ parameters.container_config.config.language }}) | ✅ |
          | Docker Compose | ${{ parameters.container_config.config.include_docker_compose and '✅' or '❌' }} |
          | Kubernetes Manifests | ${{ parameters.container_config.config.include_kubernetes and '✅' or '❌' }} |
          | Helm Chart | ${{ parameters.container_config.config.include_helm and '✅' or '❌' }} |

          ### Configuration

          | Setting | Value |
          |---|---|
          | Language | ${{ parameters.container_config.config.language }} ${{ parameters.container_config.config.runtime_version }} |
          | Port | ${{ parameters.container_config.config.app_port }} |
          | Namespace | ${{ parameters.container_config.config.k8s_namespace }} |
          | Domain | ${{ parameters.container_config.config.domain }} |
          | Replicas | ${{ parameters.container_config.config.min_replicas }}–${{ parameters.container_config.config.max_replicas }} |

          ### Next Steps

          1. Review the generated Dockerfile and update the build commands if needed
          2. Update `SECRET_VALUE` placeholders in `containers/kubernetes/secret.yaml`
          3. Push image to `${{ parameters.container_config.config.container_registry }}/${{ parameters.client_name }}`
          4. Apply manifests: `kubectl apply -f containers/kubernetes/`
          5. Or deploy with Helm: `helm install ${{ parameters.client_name }} ./containers/helm`

  output:
    links:
      - title: View Pull Request
        url: ${{ steps['publish-pr'].output.remoteUrl }}
EOF

cat > templates/container-setup/README.md << 'EOF'
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
EOF

echo "✅ Container Setup template created"

# ────────────────────────────────────────────────────────────────
# UPDATE ROOT CATALOG-INFO.YAML
# ────────────────────────────────────────────────────────────────

cat > catalog-info.yaml << 'EOF'
apiVersion: backstage.io/v1alpha1
kind: Location
metadata:
  name: opt-it-catalog
  description: Opt IT Backstage Template Catalog
spec:
  targets:
    - ./templates/aws-infrastructure/template.yaml
    - ./templates/azure-infrastructure/template.yaml
    - ./templates/gcp-infrastructure/template.yaml
    - ./templates/cicd-pipeline/template.yaml
    - ./templates/observability-stack/template.yaml
    - ./templates/security-scan/template.yaml
    - ./templates/container-setup/template.yaml
EOF

echo "✅ catalog-info.yaml updated with Phase 4 templates"

# ────────────────────────────────────────────────────────────────
# COMMIT AND PUSH
# ────────────────────────────────────────────────────────────────

git add .
git commit -m "feat(phase4): add security-scan and container-setup templates"
git push origin main

echo ""
echo "================================================================"
echo "  ✅ Phase 4 templates pushed!"
echo ""
echo "  Next steps:"
echo "  1. Add SecurityPicker to packages/app/src/components/SecurityPicker/"
echo "  2. Add ContainerPicker to packages/app/src/components/ContainerPicker/"
echo "  3. Register both in App.tsx"
echo "  4. Restart Backstage — yarn dev"
echo "================================================================"