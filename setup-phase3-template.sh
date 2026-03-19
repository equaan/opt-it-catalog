#!/bin/bash
# ================================================================
# Opt IT — Phase 3 Templates Setup
# Run from inside your opt-it-catalog directory:
#   cd opt-it-catalog
#   bash setup-phase3-templates.sh
# ================================================================

set -e

echo "================================================================"
echo "  Opt IT — Creating Phase 3 Templates"
echo "================================================================"

mkdir -p templates/cicd-pipeline/skeleton
mkdir -p templates/observability-stack/skeleton/prometheus/alert-rules
mkdir -p templates/observability-stack/skeleton/grafana/provisioning/datasources
mkdir -p templates/observability-stack/skeleton/grafana/provisioning/dashboards
mkdir -p templates/observability-stack/skeleton/grafana/dashboards
mkdir -p templates/observability-stack/skeleton/alertmanager
mkdir -p templates/observability-stack/skeleton/docker-compose
mkdir -p templates/observability-stack/skeleton/helm

# ────────────────────────────────────────────────────────────────
# CICD PIPELINE TEMPLATE
# ────────────────────────────────────────────────────────────────

cat > templates/cicd-pipeline/catalog-info.yaml << 'EOF'
apiVersion: backstage.io/v1alpha1
kind: Location
metadata:
  name: cicd-pipeline-template
  description: Opt IT CI/CD Pipeline Template
spec:
  targets:
    - ./template.yaml
EOF

cat > templates/cicd-pipeline/template.yaml << 'EOF'
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: cicd-pipeline
  title: CI/CD Pipeline Setup
  description: Sets up CI/CD pipelines for a client repository. Supports GitHub Actions, Jenkins, GitLab CI, and ArgoCD.
  tags:
    - cicd
    - github-actions
    - jenkins
    - gitlab-ci
    - argocd
    - phase-3
spec:
  owner: devops
  type: cicd

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

    - title: Step 2 - CI/CD Tools
      required:
        - cicd_config
      properties:
        cicd_config:
          title: CI/CD Configuration
          type: object
          description: Select CI/CD tools and configure each pipeline
          ui:field: CICDPicker

  steps:

    - id: fetch-github-actions
      name: Fetch GitHub Actions Workflows
      if: ${{ parameters.cicd_config.tools and parameters.cicd_config.tools.includes('github_actions') }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/cicd/github-actions/workflows
        targetPath: ./.github/workflows
        values:
          client_name: ${{ parameters.client_name }}
          environment: ${{ parameters.environment }}

    - id: fetch-jenkins
      name: Fetch Jenkinsfile
      if: ${{ parameters.cicd_config.tools and parameters.cicd_config.tools.includes('jenkins') }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/cicd/jenkins
        targetPath: ./
        values:
          client_name: ${{ parameters.client_name }}
          environment: ${{ parameters.environment }}

    - id: fetch-gitlab-ci
      name: Fetch GitLab CI Config
      if: ${{ parameters.cicd_config.tools and parameters.cicd_config.tools.includes('gitlab_ci') }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/cicd/gitlab-ci
        targetPath: ./
        values:
          client_name: ${{ parameters.client_name }}
          environment: ${{ parameters.environment }}

    - id: fetch-argocd
      name: Fetch ArgoCD Manifests
      if: ${{ parameters.cicd_config.tools and parameters.cicd_config.tools.includes('argocd') }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/cicd/argocd/base
        targetPath: ./argocd
        values:
          client_name:        ${{ parameters.client_name }}
          environment:        ${{ parameters.environment }}
          repo_url:           https://github.com/${{ parameters.repoUrl }}
          cluster_url:        ${{ parameters.cicd_config.config.argocd_cluster_url }}
          app_namespace:      ${{ parameters.cicd_config.config.argocd_app_namespace }}
          manifests_path:     ${{ parameters.cicd_config.config.argocd_manifests_path }}
          target_revision:    ${{ parameters.cicd_config.config.argocd_target_revision }}
          argocd_prune:       ${{ parameters.cicd_config.config.argocd_prune }}
          argocd_self_heal:   ${{ parameters.cicd_config.config.argocd_self_heal }}

    - id: publish-pr
      name: Open Pull Request on Client Repository
      action: publish:github:pull-request
      input:
        repoUrl: ${{ parameters.repoUrl }}
        branchName: cicd/${{ parameters.client_name }}-${{ parameters.environment }}-${{ parameters.cicd_config.tools or 'setup' }}
        targetBranchName: main
        update: true
        title: "feat(cicd): add ${{ parameters.cicd_config.tools }} pipelines for ${{ parameters.client_name }}"
        description: |
          ## CI/CD Pipeline Setup 🚀

          Provisioned by **Opt IT Backstage**.

          ### Tools Added
          | Tool | Status |
          |---|---|
          | GitHub Actions | ${{ parameters.cicd_config.tools and parameters.cicd_config.tools.includes('github_actions') and '✅' or '❌' }} |
          | Jenkins | ${{ parameters.cicd_config.tools and parameters.cicd_config.tools.includes('jenkins') and '✅' or '❌' }} |
          | GitLab CI | ${{ parameters.cicd_config.tools and parameters.cicd_config.tools.includes('gitlab_ci') and '✅' or '❌' }} |
          | ArgoCD | ${{ parameters.cicd_config.tools and parameters.cicd_config.tools.includes('argocd') and '✅' or '❌' }} |

          > Review pipeline configuration before merging.

  output:
    links:
      - title: View Pull Request
        url: ${{ steps['publish-pr'].output.remoteUrl }}
EOF

cat > templates/cicd-pipeline/README.md << 'EOF'
# CI/CD Pipeline Template

Sets up CI/CD pipelines for a client repository.

## Supported Tools

| Tool | Type | Config file |
|---|---|---|
| GitHub Actions | Push-based CI/CD | `.github/workflows/` |
| Jenkins | Push-based CI/CD | `Jenkinsfile` |
| GitLab CI | Push-based CI/CD | `.gitlab-ci.yml` |
| ArgoCD | GitOps (pull-based) | `argocd/` |

## Phase

Phase 3 — CI/CD Pipeline.
EOF

echo "✅ CI/CD Pipeline template created"

# ────────────────────────────────────────────────────────────────
# OBSERVABILITY STACK TEMPLATE
# ────────────────────────────────────────────────────────────────

cat > templates/observability-stack/catalog-info.yaml << 'EOF'
apiVersion: backstage.io/v1alpha1
kind: Location
metadata:
  name: observability-stack-template
  description: Opt IT Observability Stack Template
spec:
  targets:
    - ./template.yaml
EOF

cat > templates/observability-stack/template.yaml << 'EOF'
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: observability-stack
  title: Observability Stack Setup
  description: Sets up Prometheus + Grafana + Alertmanager for a client. Supports Docker Compose and Helm deployment.
  tags:
    - observability
    - prometheus
    - grafana
    - alertmanager
    - phase-3
spec:
  owner: devops
  type: observability

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

    - title: Step 2 - Observability Configuration
      required:
        - obs_config
      properties:
        obs_config:
          title: Observability Configuration
          type: object
          description: Configure Prometheus, Grafana, alert rules, and notifications
          ui:field: ObservabilityPicker
          ui:options:
            environment: ${{ parameters.environment }}

  steps:

    - id: fetch-prometheus
      name: Fetch Prometheus Config
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/observability/prometheus
        targetPath: ./observability/prometheus
        values:
          client_name:        ${{ parameters.client_name }}
          environment:        ${{ parameters.environment }}
          scrape_interval:    ${{ parameters.obs_config.config.scrape_interval }}
          scrape_app_metrics: ${{ parameters.obs_config.config.scrape_app_metrics }}
          app_metrics_port:   ${{ parameters.obs_config.config.app_metrics_port }}

    - id: fetch-grafana
      name: Fetch Grafana Config
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/observability/grafana
        targetPath: ./observability/grafana
        values:
          client_name:            ${{ parameters.client_name }}
          environment:            ${{ parameters.environment }}
          grafana_port:           ${{ parameters.obs_config.config.grafana_port }}
          grafana_admin_password: ${{ parameters.obs_config.config.grafana_admin_password }}
          scrape_interval:        ${{ parameters.obs_config.config.scrape_interval }}
          alert_email:            ${{ parameters.obs_config.config.alert_email }}

    - id: fetch-alertmanager
      name: Fetch Alertmanager Config
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/observability/alertmanager
        targetPath: ./observability/alertmanager
        values:
          client_name:   ${{ parameters.client_name }}
          environment:   ${{ parameters.environment }}
          alert_email:   ${{ parameters.obs_config.config.alert_email }}
          slack_webhook: ${{ parameters.obs_config.config.slack_webhook }}
          slack_channel: ${{ parameters.obs_config.config.slack_channel }}

    - id: fetch-docker-compose
      name: Fetch Docker Compose Stack
      if: ${{ parameters.obs_config.config.deployment_method === 'docker-compose' }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/observability/docker-compose
        targetPath: ./observability
        values:
          client_name:    ${{ parameters.client_name }}
          environment:    ${{ parameters.environment }}
          grafana_port:   ${{ parameters.obs_config.config.grafana_port }}
          retention_days: ${{ parameters.obs_config.config.retention_days }}

    - id: fetch-helm
      name: Fetch Helm Chart
      if: ${{ parameters.obs_config.config.deployment_method === 'helm' }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/observability/helm
        targetPath: ./observability/helm
        values:
          client_name:            ${{ parameters.client_name }}
          environment:            ${{ parameters.environment }}
          grafana_port:           ${{ parameters.obs_config.config.grafana_port }}
          grafana_admin_password: ${{ parameters.obs_config.config.grafana_admin_password }}
          scrape_interval:        ${{ parameters.obs_config.config.scrape_interval }}
          retention_days:         ${{ parameters.obs_config.config.retention_days }}

    - id: publish-pr
      name: Open Pull Request on Client Repository
      action: publish:github:pull-request
      input:
        repoUrl: ${{ parameters.repoUrl }}
        branchName: observability/${{ parameters.client_name }}-${{ parameters.environment }}-${{ parameters.obs_config.config.deployment_method }}
        targetBranchName: main
        update: true
        title: "feat(observability): add Prometheus + Grafana stack for ${{ parameters.client_name }}"
        description: |
          ## Observability Stack Setup 📊

          Provisioned by **Opt IT Backstage**.

          ### Configuration

          | Setting | Value |
          |---|---|
          | **Client** | ${{ parameters.client_name }} |
          | **Environment** | ${{ parameters.environment }} |
          | **Deployment** | ${{ parameters.obs_config.config.deployment_method }} |
          | **Scrape Interval** | ${{ parameters.obs_config.config.scrape_interval }} |
          | **Retention** | ${{ parameters.obs_config.config.retention_days }} days |
          | **Grafana Port** | ${{ parameters.obs_config.config.grafana_port }} |

          ### Next Steps

          ${% if obs_config.config.deployment_method == 'docker-compose' %}
          ```bash
          cd observability/
          docker compose up -d
          # Grafana: http://localhost:${{ parameters.obs_config.config.grafana_port }}
          # Prometheus: http://localhost:9090
          ```
          ${% else %}
          ```bash
          cd observability/helm/
          helm dependency update
          helm install obs . -n monitoring --create-namespace
          ```
          ${% endif %}

          > ⚠️ Change the Grafana admin password after first login.

  output:
    links:
      - title: View Pull Request
        url: ${{ steps['publish-pr'].output.remoteUrl }}
EOF

cat > templates/observability-stack/README.md << 'EOF'
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
EOF

echo "✅ Observability Stack template created"

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
EOF

echo "✅ catalog-info.yaml updated"

# ────────────────────────────────────────────────────────────────
# COMMIT AND PUSH
# ────────────────────────────────────────────────────────────────

git add .
git commit -m "feat(phase3): add cicd-pipeline and observability-stack templates"
git push origin main

echo ""
echo "================================================================"
echo "  ✅ Phase 3 templates pushed!"
echo ""
echo "  Next steps:"
echo "  1. Add CICDPicker to packages/app/src/components/CICDPicker/"
echo "  2. Add ObservabilityPicker to packages/app/src/components/ObservabilityPicker/"
echo "  3. Register both in App.tsx"
echo "  4. Restart Backstage — yarn dev"
echo "================================================================"