#!/bin/bash
# ================================================================
# Opt IT — Phase 5 Full Onboarding Wizard Template Setup
# Run from inside your opt-it-catalog directory:
#   cd opt-it-catalog
#   bash setup-phase5-template.sh
# ================================================================

set -e

echo "================================================================"
echo "  Opt IT — Creating Phase 5 Full Onboarding Wizard"
echo "================================================================"

mkdir -p templates/client-onboarding

# ────────────────────────────────────────────────────────────────
# CATALOG INFO
# ────────────────────────────────────────────────────────────────

cat > templates/client-onboarding/catalog-info.yaml << 'EOF'
apiVersion: backstage.io/v1alpha1
kind: Location
metadata:
  name: client-onboarding-template
  description: Opt IT Full Client Onboarding Wizard
spec:
  targets:
    - ./template.yaml
EOF

# ────────────────────────────────────────────────────────────────
# TEMPLATE.YAML
# The full onboarding wizard — 7 pages, one PR
# ────────────────────────────────────────────────────────────────

cat > templates/client-onboarding/template.yaml << 'EOF'
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: client-onboarding
  title: "⭐ Full Client Onboarding"
  description: Complete end-to-end client onboarding — infrastructure, CI/CD, observability, security, and containers in one PR. Start here for new clients.
  tags:
    - onboarding
    - featured
    - aws
    - azure
    - gcp
    - cicd
    - observability
    - security
    - containers
    - phase-5
spec:
  owner: devops
  type: onboarding

  parameters:

    # ─────────────────────────────────────────
    # PAGE 1 — Client Basics
    # ─────────────────────────────────────────
    - title: "Step 1 — Client Information"
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
          description: "The GitHub repository where all generated files will be committed via PR"
          ui:field: RepoUrlPicker
          ui:options:
            allowedHosts:
              - github.com

        engineer_name:
          title: Assigned Engineer
          type: string
          description: "Your name — appears in the PR description and generated docs"
          default: ""

    # ─────────────────────────────────────────
    # PAGE 2 — Cloud Infrastructure
    # ─────────────────────────────────────────
    - title: "Step 2 — Cloud Infrastructure"
      properties:
        cloud_provider:
          title: Cloud Provider
          type: string
          description: "Select the cloud provider for this client's infrastructure. Select None to skip infrastructure."
          enum: [aws, azure, gcp, none]
          enumNames:
            - "AWS — Amazon Web Services"
            - "Azure — Microsoft Azure"
            - "GCP — Google Cloud Platform"
            - "None — Skip infrastructure setup"
          default: none

      dependencies:
        cloud_provider:
          oneOf:
            - properties:
                cloud_provider:
                  enum: [none]

            - properties:
                cloud_provider:
                  enum: [aws]
                aws_resources:
                  title: AWS Resources
                  type: object
                  description: Select AWS resources to provision
                  ui:field: AwsResourcePicker
                  ui:options:
                    environment: ${{ parameters.environment }}
              required:
                - aws_resources

            - properties:
                cloud_provider:
                  enum: [azure]
                azure_resources:
                  title: Azure Resources
                  type: object
                  description: Select Azure resources to provision
                  ui:field: AzureResourcePicker
                  ui:options:
                    environment: ${{ parameters.environment }}
              required:
                - azure_resources

            - properties:
                cloud_provider:
                  enum: [gcp]
                gcp_resources:
                  title: GCP Resources
                  type: object
                  description: Select GCP resources to provision
                  ui:field: GcpResourcePicker
                  ui:options:
                    environment: ${{ parameters.environment }}
              required:
                - gcp_resources

    # ─────────────────────────────────────────
    # PAGE 3 — CI/CD
    # ─────────────────────────────────────────
    - title: "Step 3 — CI/CD Pipeline"
      properties:
        setup_cicd:
          title: Set up CI/CD pipeline?
          type: boolean
          default: false
          ui:widget: radio

      dependencies:
        setup_cicd:
          oneOf:
            - properties:
                setup_cicd:
                  enum: [false]

            - properties:
                setup_cicd:
                  enum: [true]
                cicd_config:
                  title: CI/CD Configuration
                  type: object
                  description: Select CI/CD tools and configure pipelines
                  ui:field: CICDPicker
              required:
                - cicd_config

    # ─────────────────────────────────────────
    # PAGE 4 — Observability
    # ─────────────────────────────────────────
    - title: "Step 4 — Observability"
      properties:
        setup_observability:
          title: Set up observability stack?
          type: boolean
          default: false
          ui:widget: radio

      dependencies:
        setup_observability:
          oneOf:
            - properties:
                setup_observability:
                  enum: [false]

            - properties:
                setup_observability:
                  enum: [true]
                obs_config:
                  title: Observability Configuration
                  type: object
                  description: Configure Prometheus, Grafana, and alerting
                  ui:field: ObservabilityPicker
                  ui:options:
                    environment: ${{ parameters.environment }}
              required:
                - obs_config

    # ─────────────────────────────────────────
    # PAGE 5 — Security
    # ─────────────────────────────────────────
    - title: "Step 5 — Security Scanning"
      properties:
        setup_security:
          title: Set up security scanning?
          type: boolean
          default: false
          ui:widget: radio

      dependencies:
        setup_security:
          oneOf:
            - properties:
                setup_security:
                  enum: [false]

            - properties:
                setup_security:
                  enum: [true]
                security_config:
                  title: Security Configuration
                  type: object
                  description: Configure Trivy and OWASP scanning
                  ui:field: SecurityPicker
                  ui:options:
                    environment: ${{ parameters.environment }}
              required:
                - security_config

    # ─────────────────────────────────────────
    # PAGE 6 — Containers
    # ─────────────────────────────────────────
    - title: "Step 6 — Container Setup"
      properties:
        setup_containers:
          title: Set up containerization?
          type: boolean
          default: false
          ui:widget: radio

      dependencies:
        setup_containers:
          oneOf:
            - properties:
                setup_containers:
                  enum: [false]

            - properties:
                setup_containers:
                  enum: [true]
                container_config:
                  title: Container Configuration
                  type: object
                  description: Configure Dockerfile, Docker Compose, Kubernetes, and Helm
                  ui:field: ContainerPicker
                  ui:options:
                    environment: ${{ parameters.environment }}
              required:
                - container_config

  # ─────────────────────────────────────────
  # STEPS — all conditional, one PR
  # ─────────────────────────────────────────
  steps:

    # ══ INFRASTRUCTURE ══════════════════════════════════════════

    # ── AWS ─────────────────────────────────────────────────────

    - id: fetch-aws-vpc
      name: Fetch AWS VPC Module
      if: ${{ parameters.cloud_provider === 'aws' and parameters.aws_resources.resources and parameters.aws_resources.resources.includes('vpc') }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-aws-vpc-v1.0.0/terraform/aws/networking/vpc
        targetPath: ./terraform/modules/vpc
        values: {}

    - id: fetch-aws-subnets
      name: Fetch AWS Subnets Module
      if: ${{ parameters.cloud_provider === 'aws' and parameters.aws_resources.resources and parameters.aws_resources.resources.includes('vpc') }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-aws-subnets-v1.0.0/terraform/aws/networking/subnets
        targetPath: ./terraform/modules/subnets
        values: {}

    - id: fetch-aws-security-groups
      name: Fetch AWS Security Groups Module
      if: ${{ parameters.cloud_provider === 'aws' and parameters.aws_resources.resources and (parameters.aws_resources.resources.includes('ec2') or parameters.aws_resources.resources.includes('rds')) }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-aws-security-groups-v1.0.0/terraform/aws/networking/security-groups
        targetPath: ./terraform/modules/security-groups
        values: {}

    - id: fetch-aws-ec2
      name: Fetch AWS EC2 Module
      if: ${{ parameters.cloud_provider === 'aws' and parameters.aws_resources.resources and parameters.aws_resources.resources.includes('ec2') }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-aws-ec2-v1.0.0/terraform/aws/compute/ec2
        targetPath: ./terraform/modules/ec2
        values: {}

    - id: fetch-aws-s3
      name: Fetch AWS S3 Module
      if: ${{ parameters.cloud_provider === 'aws' and parameters.aws_resources.resources and parameters.aws_resources.resources.includes('s3') }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-aws-s3-v1.0.0/terraform/aws/storage/s3
        targetPath: ./terraform/modules/s3
        values: {}

    - id: fetch-aws-rds
      name: Fetch AWS RDS Module
      if: ${{ parameters.cloud_provider === 'aws' and parameters.aws_resources.resources and parameters.aws_resources.resources.includes('rds') }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-aws-rds-v1.0.0/terraform/aws/database/rds
        targetPath: ./terraform/modules/rds
        values: {}

    - id: fetch-aws-iam
      name: Fetch AWS IAM Module
      if: ${{ parameters.cloud_provider === 'aws' and parameters.aws_resources.resources and parameters.aws_resources.resources.includes('iam') }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-aws-iam-baseline-v1.0.0/terraform/aws/iam/baseline
        targetPath: ./terraform/modules/iam-baseline
        values: {}

    - id: generate-aws-terraform
      name: Generate AWS Terraform Root
      if: ${{ parameters.cloud_provider === 'aws' }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-catalog/tree/main/templates/aws-infrastructure/skeleton/terraform
        targetPath: ./terraform
        values:
          client_name:       ${{ parameters.client_name }}
          environment:       ${{ parameters.environment }}
          aws_region:        us-east-1
          provision_vpc:     ${{ parameters.aws_resources.resources and parameters.aws_resources.resources.includes('vpc') }}
          provision_ec2:     ${{ parameters.aws_resources.resources and parameters.aws_resources.resources.includes('ec2') }}
          provision_s3:      ${{ parameters.aws_resources.resources and parameters.aws_resources.resources.includes('s3') }}
          provision_rds:     ${{ parameters.aws_resources.resources and parameters.aws_resources.resources.includes('rds') }}
          vpc_cidr:          ${{ parameters.aws_resources.config.vpc_cidr }}
          ec2_instance_type: ${{ parameters.aws_resources.config.ec2_instance_type }}
          s3_versioning:     ${{ parameters.aws_resources.config.s3_versioning }}
          rds_engine:        ${{ parameters.aws_resources.config.rds_engine }}

    # ── AZURE ────────────────────────────────────────────────────

    - id: fetch-azure-resource-group
      name: Fetch Azure Resource Group Module
      if: ${{ parameters.cloud_provider === 'azure' }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-azure-resource-group-v1.0.0/terraform/azure/base/resource-group
        targetPath: ./terraform/modules/resource-group
        values: {}

    - id: fetch-azure-vnet
      name: Fetch Azure VNet Module
      if: ${{ parameters.cloud_provider === 'azure' and parameters.azure_resources.resources and parameters.azure_resources.resources.includes('vnet') }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-azure-vnet-v1.0.0/terraform/azure/networking/vnet
        targetPath: ./terraform/modules/vnet
        values: {}

    - id: fetch-azure-nsg
      name: Fetch Azure NSG Module
      if: ${{ parameters.cloud_provider === 'azure' and parameters.azure_resources.resources and parameters.azure_resources.resources.includes('nsg') }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-azure-nsg-v1.0.0/terraform/azure/networking/nsg
        targetPath: ./terraform/modules/nsg
        values: {}

    - id: fetch-azure-vm
      name: Fetch Azure VM Module
      if: ${{ parameters.cloud_provider === 'azure' and parameters.azure_resources.resources and parameters.azure_resources.resources.includes('vm') }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-azure-vm-v1.0.0/terraform/azure/compute/vm
        targetPath: ./terraform/modules/vm
        values: {}

    - id: fetch-azure-blob
      name: Fetch Azure Blob Storage Module
      if: ${{ parameters.cloud_provider === 'azure' and parameters.azure_resources.resources and parameters.azure_resources.resources.includes('blob') }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-azure-blob-storage-v1.0.0/terraform/azure/storage/blob
        targetPath: ./terraform/modules/blob-storage
        values: {}

    - id: fetch-azure-sql
      name: Fetch Azure SQL Module
      if: ${{ parameters.cloud_provider === 'azure' and parameters.azure_resources.resources and parameters.azure_resources.resources.includes('sql') }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-azure-sql-flexible-v1.0.0/terraform/azure/database/sql-flexible
        targetPath: ./terraform/modules/sql-flexible
        values: {}

    - id: generate-azure-terraform
      name: Generate Azure Terraform Root
      if: ${{ parameters.cloud_provider === 'azure' }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-catalog/tree/main/templates/azure-infrastructure/skeleton/terraform
        targetPath: ./terraform
        values:
          client_name:           ${{ parameters.client_name }}
          environment:           ${{ parameters.environment }}
          location:              ${{ parameters.azure_resources.foundation.location }}
          resource_group_suffix: ${{ parameters.azure_resources.foundation.resource_group_suffix }}
          provision_vnet:        ${{ parameters.azure_resources.resources and parameters.azure_resources.resources.includes('vnet') }}
          provision_nsg:         ${{ parameters.azure_resources.resources and parameters.azure_resources.resources.includes('nsg') }}
          provision_vm:          ${{ parameters.azure_resources.resources and parameters.azure_resources.resources.includes('vm') }}
          provision_blob:        ${{ parameters.azure_resources.resources and parameters.azure_resources.resources.includes('blob') }}
          provision_sql:         ${{ parameters.azure_resources.resources and parameters.azure_resources.resources.includes('sql') }}
          vnet_address_space:    ${{ parameters.azure_resources.config.vnet_address_space }}
          vm_size:               ${{ parameters.azure_resources.config.vm_size }}
          db_engine:             ${{ parameters.azure_resources.config.db_engine }}
          storage_suffix:        ${{ parameters.azure_resources.config.storage_suffix }}
          replication_type:      ${{ parameters.azure_resources.config.account_replication_type }}
          container_names:       ${{ parameters.azure_resources.config.container_names }}
          db_version:            ${{ parameters.azure_resources.config.db_version }}
          sku_name:              ${{ parameters.azure_resources.config.sku_name }}
          ha_mode:               ${{ parameters.azure_resources.config.high_availability_mode }}
          admin_username:        ${{ parameters.azure_resources.config.admin_username }}
          allowed_ssh_source:    ${{ parameters.azure_resources.config.allowed_ssh_source_prefixes }}
          db_port:               ${{ parameters.azure_resources.config.db_port }}
          public_subnet_prefixes: ${{ parameters.azure_resources.config.public_subnet_prefixes }}
          private_subnet_prefixes: ${{ parameters.azure_resources.config.private_subnet_prefixes }}
          enable_nat_gateway:    ${{ parameters.azure_resources.config.enable_nat_gateway }}

    # ── GCP ──────────────────────────────────────────────────────

    - id: fetch-gcp-vpc
      name: Fetch GCP VPC Module
      if: ${{ parameters.cloud_provider === 'gcp' }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-gcp-vpc-v1.0.0/terraform/GCP/networking/vpc
        targetPath: ./terraform/modules/vpc
        values: {}

    - id: fetch-gcp-firewall
      name: Fetch GCP Firewall Module
      if: ${{ parameters.cloud_provider === 'gcp' and parameters.gcp_resources.resources and parameters.gcp_resources.resources.includes('firewall') }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-gcp-firewall-v1.0.0/terraform/GCP/networking/firewall
        targetPath: ./terraform/modules/firewall
        values: {}

    - id: fetch-gcp-gce
      name: Fetch GCP GCE Module
      if: ${{ parameters.cloud_provider === 'gcp' and parameters.gcp_resources.resources and parameters.gcp_resources.resources.includes('gce') }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-gcp-gce-v1.0.0/terraform/GCP/compute/gce
        targetPath: ./terraform/modules/gce
        values: {}

    - id: fetch-gcp-gcs
      name: Fetch GCP GCS Module
      if: ${{ parameters.cloud_provider === 'gcp' and parameters.gcp_resources.resources and parameters.gcp_resources.resources.includes('gcs') }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-gcp-gcs-v1.0.0/terraform/GCP/storage/gcs
        targetPath: ./terraform/modules/gcs
        values: {}

    - id: fetch-gcp-cloud-sql
      name: Fetch GCP Cloud SQL Module
      if: ${{ parameters.cloud_provider === 'gcp' and parameters.gcp_resources.resources and parameters.gcp_resources.resources.includes('cloud_sql') }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-gcp-cloud-sql-v1.0.0/terraform/GCP/database/cloud-sql
        targetPath: ./terraform/modules/cloud-sql
        values: {}

    - id: generate-gcp-terraform
      name: Generate GCP Terraform Root
      if: ${{ parameters.cloud_provider === 'gcp' }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-catalog/tree/main/templates/gcp-infrastructure/skeleton/terraform
        targetPath: ./terraform
        values:
          client_name:         ${{ parameters.client_name }}
          environment:         ${{ parameters.environment }}
          project_id:          ${{ parameters.gcp_resources.foundation.project_id }}
          region:              ${{ parameters.gcp_resources.foundation.region }}
          zone:                ${{ parameters.gcp_resources.foundation.zone }}
          provision_vpc:       ${{ parameters.gcp_resources.resources and parameters.gcp_resources.resources.includes('vpc') }}
          provision_firewall:  ${{ parameters.gcp_resources.resources and parameters.gcp_resources.resources.includes('firewall') }}
          provision_gce:       ${{ parameters.gcp_resources.resources and parameters.gcp_resources.resources.includes('gce') }}
          provision_gcs:       ${{ parameters.gcp_resources.resources and parameters.gcp_resources.resources.includes('gcs') }}
          provision_cloud_sql: ${{ parameters.gcp_resources.resources and parameters.gcp_resources.resources.includes('cloud_sql') }}
          public_subnet_cidr:  ${{ parameters.gcp_resources.config.public_subnet_cidr }}
          private_subnet_cidr: ${{ parameters.gcp_resources.config.private_subnet_cidr }}
          enable_cloud_nat:    ${{ parameters.gcp_resources.config.enable_cloud_nat }}
          allowed_ssh_ranges:  ${{ parameters.gcp_resources.config.allowed_ssh_source_ranges }}
          db_port:             ${{ parameters.gcp_resources.config.db_port }}
          machine_type:        ${{ parameters.gcp_resources.config.machine_type }}
          boot_disk_type:      ${{ parameters.gcp_resources.config.boot_disk_type }}
          bucket_suffix:       ${{ parameters.gcp_resources.config.bucket_suffix }}
          storage_class:       ${{ parameters.gcp_resources.config.storage_class }}
          enable_versioning:   ${{ parameters.gcp_resources.config.enable_versioning }}
          db_engine:           ${{ parameters.gcp_resources.config.db_engine }}
          db_version:          ${{ parameters.gcp_resources.config.db_version }}
          tier:                ${{ parameters.gcp_resources.config.tier }}
          availability_type:   ${{ parameters.gcp_resources.config.availability_type }}

    # ══ CI/CD ════════════════════════════════════════════════════

    - id: fetch-github-actions
      name: Fetch GitHub Actions Workflows
      if: ${{ parameters.setup_cicd and parameters.cicd_config.tools and parameters.cicd_config.tools.includes('GitHub Actions') }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/cicd/github-actions/workflows
        targetPath: ./.github/workflows
        values:
          client_name: ${{ parameters.client_name }}
          environment: ${{ parameters.environment }}

    - id: fetch-jenkins
      name: Fetch Jenkinsfile
      if: ${{ parameters.setup_cicd and parameters.cicd_config.tools and parameters.cicd_config.tools.includes('Jenkins') }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/cicd/jenkins
        targetPath: ./
        values:
          client_name: ${{ parameters.client_name }}
          environment: ${{ parameters.environment }}

    - id: fetch-gitlab-ci
      name: Fetch GitLab CI Config
      if: ${{ parameters.setup_cicd and parameters.cicd_config.tools and parameters.cicd_config.tools.includes('GitLab CI') }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/cicd/gitlab-ci
        targetPath: ./
        values:
          client_name: ${{ parameters.client_name }}
          environment: ${{ parameters.environment }}

    - id: fetch-argocd
      name: Fetch ArgoCD Manifests
      if: ${{ parameters.setup_cicd and parameters.cicd_config.tools and parameters.cicd_config.tools.includes('ArgoCD') }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/cicd/argocd/base
        targetPath: ./argocd
        values:
          client_name:      ${{ parameters.client_name }}
          environment:      ${{ parameters.environment }}
          repo_url:         https://github.com/${{ parameters.repoUrl }}
          cluster_url:      ${{ parameters.cicd_config.config.argocd_cluster_url }}
          app_namespace:    ${{ parameters.cicd_config.config.argocd_app_namespace }}
          manifests_path:   ${{ parameters.cicd_config.config.argocd_manifests_path }}
          target_revision:  ${{ parameters.cicd_config.config.argocd_target_revision }}
          argocd_prune:     ${{ parameters.cicd_config.config.argocd_prune }}
          argocd_self_heal: ${{ parameters.cicd_config.config.argocd_self_heal }}

    # ══ OBSERVABILITY ════════════════════════════════════════════

    - id: fetch-prometheus
      name: Fetch Prometheus Config
      if: ${{ parameters.setup_observability }}
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
      if: ${{ parameters.setup_observability }}
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
      if: ${{ parameters.setup_observability }}
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

    - id: fetch-docker-compose-obs
      name: Fetch Observability Docker Compose
      if: ${{ parameters.setup_observability and parameters.obs_config.config.deployment_method === 'docker-compose' }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/observability/docker-compose
        targetPath: ./observability
        values:
          client_name:    ${{ parameters.client_name }}
          environment:    ${{ parameters.environment }}
          grafana_port:   ${{ parameters.obs_config.config.grafana_port }}
          retention_days: ${{ parameters.obs_config.config.retention_days }}

    - id: fetch-helm-obs
      name: Fetch Observability Helm Chart
      if: ${{ parameters.setup_observability and parameters.obs_config.config.deployment_method === 'helm' }}
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

    # ══ SECURITY ═════════════════════════════════════════════════

    - id: fetch-trivy-config
      name: Fetch Trivy Config
      if: ${{ parameters.setup_security and parameters.security_config.config.enable_trivy }}
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
      name: Fetch Trivy Workflow
      if: ${{ parameters.setup_security and parameters.security_config.config.enable_trivy }}
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

    - id: fetch-owasp-workflow
      name: Fetch OWASP Workflow
      if: ${{ parameters.setup_security and parameters.security_config.config.enable_owasp }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/security/owasp/workflow
        targetPath: ./.github/workflows
        values:
          client_name:     ${{ parameters.client_name }}
          environment:     ${{ parameters.environment }}
          owasp_fail_cvss: ${{ parameters.security_config.config.owasp_fail_cvss }}

    - id: fetch-owasp-config
      name: Fetch OWASP Config
      if: ${{ parameters.setup_security and parameters.security_config.config.enable_owasp }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/security/owasp/config
        targetPath: ./security/owasp
        values:
          client_name:     ${{ parameters.client_name }}
          environment:     ${{ parameters.environment }}
          owasp_fail_cvss: ${{ parameters.security_config.config.owasp_fail_cvss }}

    # ══ CONTAINERS ═══════════════════════════════════════════════

    - id: fetch-dockerfile
      name: Fetch Dockerfile
      if: ${{ parameters.setup_containers }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/containers/dockerfiles
        targetPath: ./containers/dockerfiles
        values:
          client_name:       ${{ parameters.client_name }}
          environment:       ${{ parameters.environment }}
          language:          ${{ parameters.container_config.config.language }}
          runtime_version:   ${{ parameters.container_config.config.runtime_version }}
          app_port:          ${{ parameters.container_config.config.app_port }}
          health_check_path: ${{ parameters.container_config.config.health_check_path }}

    - id: fetch-docker-compose-app
      name: Fetch App Docker Compose
      if: ${{ parameters.setup_containers and parameters.container_config.config.include_docker_compose }}
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/containers/docker-compose
        targetPath: ./containers/docker-compose
        values:
          client_name:          ${{ parameters.client_name }}
          environment:          ${{ parameters.environment }}
          language:             ${{ parameters.container_config.config.language }}
          app_port:             ${{ parameters.container_config.config.app_port }}
          include_database:     ${{ parameters.container_config.config.include_database }}
          db_engine:            ${{ parameters.container_config.config.db_engine }}
          db_name:              ${{ parameters.container_config.config.db_name }}
          db_user:              ${{ parameters.container_config.config.db_user }}
          db_connection_string: "postgresql://${{ parameters.container_config.config.db_user }}:password@db:5432/${{ parameters.container_config.config.db_name }}"
          include_redis:        ${{ parameters.container_config.config.include_redis }}

    - id: fetch-kubernetes
      name: Fetch Kubernetes Manifests
      if: ${{ parameters.setup_containers and parameters.container_config.config.include_kubernetes }}
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

    - id: fetch-helm-app
      name: Fetch App Helm Chart
      if: ${{ parameters.setup_containers and parameters.container_config.config.include_helm }}
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

    # ══ PUBLISH ONE PR ═══════════════════════════════════════════

    - id: publish-pr
      name: Open Onboarding Pull Request
      action: publish:github:pull-request
      input:
        repoUrl: ${{ parameters.repoUrl }}
        branchName: onboarding/${{ parameters.client_name }}-${{ parameters.environment }}
        targetBranchName: main
        update: true
        title: "feat(onboarding): complete ${{ parameters.environment }} onboarding for ${{ parameters.client_name }}"
        description: |
          ## Client Onboarding 🚀

          Provisioned by **Opt IT Backstage** — do not edit these files manually.

          **Engineer:** ${{ parameters.engineer_name or 'Opt IT' }}
          **Client:** ${{ parameters.client_name }}
          **Environment:** ${{ parameters.environment }}

          ---

          ### What Was Provisioned

          | Section | Status | Details |
          |---|---|---|
          | Cloud Infrastructure | ${{ parameters.cloud_provider !== 'none' and '✅' or '⏭️ Skipped' }} | ${{ parameters.cloud_provider !== 'none' and parameters.cloud_provider or '—' }} |
          | CI/CD Pipeline | ${{ parameters.setup_cicd and '✅' or '⏭️ Skipped' }} | ${{ parameters.setup_cicd and parameters.cicd_config.tools or '—' }} |
          | Observability | ${{ parameters.setup_observability and '✅' or '⏭️ Skipped' }} | ${{ parameters.setup_observability and parameters.obs_config.config.deployment_method or '—' }} |
          | Security Scanning | ${{ parameters.setup_security and '✅' or '⏭️ Skipped' }} | ${{ parameters.setup_security and 'Trivy + OWASP' or '—' }} |
          | Containers | ${{ parameters.setup_containers and '✅' or '⏭️ Skipped' }} | ${{ parameters.setup_containers and parameters.container_config.config.language or '—' }} |

          ---

          ### Next Steps

          ${% if parameters.cloud_provider !== 'none' %}
          **Infrastructure:**
          ```bash
          cd terraform/
          terraform init
          terraform plan
          terraform apply
          ```
          ${% endif %}

          ${% if parameters.setup_observability %}
          **Observability:**
          ```bash
          cd observability/
          docker compose up -d
          ```
          ${% endif %}

          ${% if parameters.setup_containers %}
          **Containers:**
          ```bash
          cp containers/dockerfiles/Dockerfile.${{ parameters.container_config.config.language }} Dockerfile
          kubectl apply -f containers/kubernetes/
          ```
          ${% endif %}

          ---

          > ⚠️ Review all values before merging. Never merge secrets with placeholder values.

  output:
    links:
      - title: View Onboarding Pull Request
        url: ${{ steps['publish-pr'].output.remoteUrl }}
EOF

echo "✅ client-onboarding template created"

# ────────────────────────────────────────────────────────────────
# README
# ────────────────────────────────────────────────────────────────

cat > templates/client-onboarding/README.md << 'EOF'
# ⭐ Full Client Onboarding Wizard

The master onboarding template. Combines all Opt IT phases into one guided
7-step form that produces a single PR with everything a new client needs.

## What It Covers

| Step | Section | Templates Used |
|---|---|---|
| 1 | Client Basics | — |
| 2 | Cloud Infrastructure | AWS / Azure / GCP pickers |
| 3 | CI/CD Pipeline | CICDPicker |
| 4 | Observability | ObservabilityPicker |
| 5 | Security Scanning | SecurityPicker |
| 6 | Containers | ContainerPicker |
| 7 | Review + Create | — |

## Output

One PR on the client repo with all selected components.
Branch name: `onboarding/{client-name}-{environment}`

## Phase

Phase 5 — Full Onboarding Wizard.
EOF

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
    - ./templates/client-onboarding/template.yaml
    - ./templates/aws-infrastructure/template.yaml
    - ./templates/azure-infrastructure/template.yaml
    - ./templates/gcp-infrastructure/template.yaml
    - ./templates/cicd-pipeline/template.yaml
    - ./templates/observability-stack/template.yaml
    - ./templates/security-scan/template.yaml
    - ./templates/container-setup/template.yaml
EOF

echo "✅ catalog-info.yaml updated — client-onboarding listed first"

# ────────────────────────────────────────────────────────────────
# COMMIT AND PUSH
# ────────────────────────────────────────────────────────────────

git add .
git commit -m "feat(phase5): add full client onboarding wizard"
git push origin main

echo ""
echo "================================================================"
echo "  ✅ Phase 5 complete!"
echo ""
echo "  The onboarding wizard is now the first template in the catalog."
echo "  All 8 templates are live:"
echo ""
echo "  ⭐ Full Client Onboarding    ← Start here for new clients"
echo "  ├── AWS Infrastructure"
echo "  ├── Azure Infrastructure"
echo "  ├── GCP Infrastructure"
echo "  ├── CI/CD Pipeline"
echo "  ├── Observability Stack"
echo "  ├── Security Scan"
echo "  └── Container Setup"
echo "================================================================"