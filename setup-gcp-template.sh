#!/bin/bash
# ================================================================
# Opt IT — GCP Infrastructure Template Setup
# Run from inside your opt-it-catalog directory:
#   cd opt-it-catalog
#   bash setup-gcp-template.sh
# ================================================================

set -e

echo "================================================================"
echo "  Opt IT — Creating GCP Infrastructure Template"
echo "================================================================"

mkdir -p templates/gcp-infrastructure/skeleton/terraform
mkdir -p templates/gcp-infrastructure/skeleton/docs

cat > templates/gcp-infrastructure/catalog-info.yaml << 'EOF'
apiVersion: backstage.io/v1alpha1
kind: Location
metadata:
  name: gcp-infrastructure-template
  description: Opt IT GCP Infrastructure Template
spec:
  targets:
    - ./template.yaml
EOF

cat > templates/gcp-infrastructure/template.yaml << 'EOF'
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: gcp-infrastructure
  title: GCP Infrastructure Setup
  description: Provisions production-grade GCP infrastructure for a client using versioned Opt IT modules.
  tags:
    - gcp
    - terraform
    - infrastructure
    - phase-2b
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

    - title: Step 2 - GCP Resources
      required:
        - gcp_resources
      properties:
        gcp_resources:
          title: GCP Resources
          type: object
          description: Select GCP project, confirm credentials, and choose resources to provision
          ui:field: GcpResourcePicker
          ui:options:
            environment: ${{ parameters.environment }}

    - title: Step 3 - CI/CD Pipeline
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
                cicd_tool:
                  title: CI/CD Tool
                  type: string
                  enum: [github-actions, jenkins]
                  enumNames: [GitHub Actions, Jenkins]
                  default: github-actions
              required:
                - cicd_tool

  steps:

    - id: fetch-vpc
      name: Fetch VPC Module
      action: fetch:plain
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-gcp-vpc-v1.0.0/terraform/GCP/networking/vpc
        targetPath: ./terraform/modules/vpc

    - id: fetch-firewall
      name: Fetch Firewall Module
      if: ${{ parameters.gcp_resources.resources and parameters.gcp_resources.resources.includes('firewall') }}
      action: fetch:plain
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-gcp-firewall-v1.0.0/terraform/GCP/networking/firewall
        targetPath: ./terraform/modules/firewall

    - id: fetch-gce
      name: Fetch GCE Module
      if: ${{ parameters.gcp_resources.resources and parameters.gcp_resources.resources.includes('gce') }}
      action: fetch:plain
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-gcp-gce-v1.0.0/terraform/GCP/compute/gce
        targetPath: ./terraform/modules/gce

    - id: fetch-gcs
      name: Fetch GCS Module
      if: ${{ parameters.gcp_resources.resources and parameters.gcp_resources.resources.includes('gcs') }}
      action: fetch:plain
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-gcp-gcs-v1.0.0/terraform/GCP/storage/gcs
        targetPath: ./terraform/modules/gcs

    - id: fetch-cloud-sql
      name: Fetch Cloud SQL Module
      if: ${{ parameters.gcp_resources.resources and parameters.gcp_resources.resources.includes('cloud_sql') }}
      action: fetch:plain
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-gcp-cloud-sql-v1.0.0/terraform/GCP/database/cloud-sql
        targetPath: ./terraform/modules/cloud-sql

    - id: generate-terraform-root
      name: Generate Terraform Root Configuration
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-catalog/tree/main/templates/gcp-infrastructure/skeleton/terraform
        targetPath: ./terraform
        values:
          client_name:          ${{ parameters.client_name }}
          environment:          ${{ parameters.environment }}
          project_id:           ${{ parameters.gcp_resources.foundation.project_id }}
          region:               ${{ parameters.gcp_resources.foundation.region }}
          zone:                 ${{ parameters.gcp_resources.foundation.zone }}
          provision_vpc:        ${{ parameters.gcp_resources.resources and parameters.gcp_resources.resources.includes('vpc') }}
          provision_firewall:   ${{ parameters.gcp_resources.resources and parameters.gcp_resources.resources.includes('firewall') }}
          provision_gce:        ${{ parameters.gcp_resources.resources and parameters.gcp_resources.resources.includes('gce') }}
          provision_gcs:        ${{ parameters.gcp_resources.resources and parameters.gcp_resources.resources.includes('gcs') }}
          provision_cloud_sql:  ${{ parameters.gcp_resources.resources and parameters.gcp_resources.resources.includes('cloud_sql') }}
          public_subnet_cidr:   ${{ parameters.gcp_resources.config.public_subnet_cidr }}
          private_subnet_cidr:  ${{ parameters.gcp_resources.config.private_subnet_cidr }}
          enable_cloud_nat:     ${{ parameters.gcp_resources.config.enable_cloud_nat }}
          allowed_ssh_ranges:   ${{ parameters.gcp_resources.config.allowed_ssh_source_ranges }}
          db_port:              ${{ parameters.gcp_resources.config.db_port }}
          machine_type:         ${{ parameters.gcp_resources.config.machine_type }}
          boot_disk_type:       ${{ parameters.gcp_resources.config.boot_disk_type }}
          bucket_suffix:        ${{ parameters.gcp_resources.config.bucket_suffix }}
          storage_class:        ${{ parameters.gcp_resources.config.storage_class }}
          enable_versioning:    ${{ parameters.gcp_resources.config.enable_versioning }}
          db_engine:            ${{ parameters.gcp_resources.config.db_engine }}
          db_version:           ${{ parameters.gcp_resources.config.db_version }}
          tier:                 ${{ parameters.gcp_resources.config.tier }}
          availability_type:    ${{ parameters.gcp_resources.config.availability_type }}

    - id: fetch-github-actions
      name: Fetch GitHub Actions Workflows
      if: ${{ parameters.setup_cicd and parameters.cicd_tool === 'github-actions' }}
      action: fetch:plain
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/cicd/github-actions/workflows
        targetPath: ./.github/workflows

    - id: fetch-jenkins
      name: Fetch Jenkins Pipeline
      if: ${{ parameters.setup_cicd and parameters.cicd_tool === 'jenkins' }}
      action: fetch:plain
      input:
        url: https://github.com/equaan/opt-it-modules/tree/main/cicd/jenkins
        targetPath: ./cicd/jenkins

    - id: publish-pr
      name: Open Pull Request on Client Repository
      action: publish:github:pull-request
      input:
        repoUrl: ${{ parameters.repoUrl }}
        branchName: infra/${{ parameters.client_name }}-${{ parameters.environment }}-gcp-${{ parameters.gcp_resources.resources or 'setup' }}
        targetBranchName: main
        update: true
        title: "feat(infra): provision GCP ${{ parameters.environment }} infrastructure for ${{ parameters.client_name }}"
        description: |
          ## GCP Infrastructure Onboarding 🚀

          Provisioned by **Opt IT Backstage** — do not edit these files manually.

          ### Configuration Summary

          | Field | Value |
          |---|---|
          | **Client** | ${{ parameters.client_name }} |
          | **Environment** | ${{ parameters.environment }} |
          | **GCP Project** | ${{ parameters.gcp_resources.foundation.project_id }} |
          | **Region** | ${{ parameters.gcp_resources.foundation.region }} |
          | **Resources** | ${{ parameters.gcp_resources.resources }} |

          ### Next Steps

          1. Review all configuration values
          2. Run: `gcloud auth application-default login`
          3. Set `TF_VAR_admin_password` if Cloud SQL was selected
          4. Merge this PR
          5. Run `terraform init && terraform plan` from the `terraform/` directory
          6. Run `terraform apply` after plan is reviewed

          > ⚠️ Review all values before merging.

  output:
    links:
      - title: View Pull Request
        url: ${{ steps['publish-pr'].output.remoteUrl }}
EOF

echo "✅ template.yaml created"

cat > templates/gcp-infrastructure/skeleton/terraform/main.tf << 'SKELEOF'
# ================================================================
# ${{ values.client_name }} — ${{ values.environment }} — GCP Infrastructure
# Generated by Opt IT Backstage
# DO NOT EDIT MANUALLY
# ================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Uncomment to configure remote state:
  # backend "gcs" {
  #   bucket = "${{ values.client_name }}-${{ values.environment }}-tfstate"
  #   prefix = "terraform/state"
  # }
}

# ────────────────────────────────────────────────────────────────
# VPC — always provisioned (GCP networking foundation)
# ────────────────────────────────────────────────────────────────

module "vpc" {
  source = "./modules/vpc"

  client_name         = var.client_name
  environment         = var.environment
  module_version      = "1.0.0"
  project_id          = var.project_id
  region              = var.region
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  enable_cloud_nat    = ${{ values.enable_cloud_nat }}
}

# ────────────────────────────────────────────────────────────────
# FIREWALL
# ${% if values.provision_firewall %}Provisioned${% else %}Not selected${% endif %}
# ────────────────────────────────────────────────────────────────

${% if values.provision_firewall %}
module "firewall" {
  source     = "./modules/firewall"

  client_name               = var.client_name
  environment               = var.environment
  module_version            = "1.0.0"
  project_id                = var.project_id
  vpc_name                  = module.vpc.vpc_name
  allowed_ssh_source_ranges = var.allowed_ssh_ranges != "" ? split(",", var.allowed_ssh_ranges) : []
  db_port                   = var.db_port
}
${% endif %}

# ────────────────────────────────────────────────────────────────
# COMPUTE ENGINE
# ${% if values.provision_gce %}Provisioned${% else %}Not selected${% endif %}
# ────────────────────────────────────────────────────────────────

${% if values.provision_gce %}
module "gce" {
  source = "./modules/gce"

  client_name          = var.client_name
  environment          = var.environment
  module_version       = "1.0.0"
  project_id           = var.project_id
  region               = var.region
  zone                 = var.zone
  subnetwork_self_link = module.vpc.private_subnet_self_link
  machine_type         = var.machine_type
  boot_disk_type       = var.boot_disk_type
  network_tags         = [module.firewall.web_server_tag, module.firewall.ssh_access_tag]
}
${% endif %}

# ────────────────────────────────────────────────────────────────
# CLOUD STORAGE
# ${% if values.provision_gcs %}Provisioned${% else %}Not selected${% endif %}
# ────────────────────────────────────────────────────────────────

${% if values.provision_gcs %}
module "gcs" {
  source = "./modules/gcs"

  client_name       = var.client_name
  environment       = var.environment
  module_version    = "1.0.0"
  project_id        = var.project_id
  bucket_suffix     = var.bucket_suffix
  storage_class     = var.storage_class
  enable_versioning = ${{ values.enable_versioning }}
}
${% endif %}

# ────────────────────────────────────────────────────────────────
# CLOUD SQL
# ${% if values.provision_cloud_sql %}Provisioned${% else %}Not selected${% endif %}
# ────────────────────────────────────────────────────────────────

${% if values.provision_cloud_sql %}
module "cloud_sql" {
  source = "./modules/cloud-sql"

  client_name       = var.client_name
  environment       = var.environment
  module_version    = "1.0.0"
  project_id        = var.project_id
  region            = var.region
  vpc_self_link     = module.vpc.vpc_self_link
  db_engine         = var.db_engine
  db_version        = var.db_version
  tier              = var.tier
  availability_type = var.availability_type
  admin_password    = var.admin_password
}
${% endif %}
SKELEOF

echo "✅ skeleton/terraform/main.tf created"

cat > templates/gcp-infrastructure/skeleton/terraform/variables.tf << 'SKELEOF'
# ================================================================
# ${{ values.client_name }} — ${{ values.environment }} — Variables
# Generated by Opt IT Backstage — DO NOT EDIT MANUALLY
# ================================================================

variable "client_name" {
  type    = string
  default = "${{ values.client_name }}"
}

variable "environment" {
  type    = string
  default = "${{ values.environment }}"
}

variable "project_id" {
  type    = string
  default = "${{ values.project_id }}"
}

variable "region" {
  type    = string
  default = "${{ values.region }}"
}

variable "zone" {
  type    = string
  default = "${{ values.zone }}"
}

variable "public_subnet_cidr" {
  type    = string
  default = "${{ values.public_subnet_cidr }}"
}

variable "private_subnet_cidr" {
  type    = string
  default = "${{ values.private_subnet_cidr }}"
}

${% if values.provision_firewall %}
variable "allowed_ssh_ranges" {
  type    = string
  default = "${{ values.allowed_ssh_ranges }}"
}

variable "db_port" {
  type    = number
  default = ${{ values.db_port }}
}
${% endif %}

${% if values.provision_gce %}
variable "machine_type" {
  type    = string
  default = "${{ values.machine_type }}"
}

variable "boot_disk_type" {
  type    = string
  default = "${{ values.boot_disk_type }}"
}
${% endif %}

${% if values.provision_gcs %}
variable "bucket_suffix" {
  type    = string
  default = "${{ values.bucket_suffix }}"
}

variable "storage_class" {
  type    = string
  default = "${{ values.storage_class }}"
}
${% endif %}

${% if values.provision_cloud_sql %}
variable "db_engine" {
  type    = string
  default = "${{ values.db_engine }}"
}

variable "db_version" {
  type    = string
  default = "${{ values.db_version }}"
}

variable "tier" {
  type    = string
  default = "${{ values.tier }}"
}

variable "availability_type" {
  type    = string
  default = "${{ values.availability_type }}"
}

variable "admin_password" {
  type      = string
  sensitive = true
  # Set via: export TF_VAR_admin_password="your-password"
}
${% endif %}
SKELEOF

echo "✅ skeleton/terraform/variables.tf created"

cat > templates/gcp-infrastructure/skeleton/terraform/outputs.tf << 'SKELEOF'
# ================================================================
# ${{ values.client_name }} — ${{ values.environment }} — Outputs
# Generated by Opt IT Backstage — DO NOT EDIT MANUALLY
# ================================================================

output "vpc_name" {
  description = "VPC network name"
  value       = module.vpc.vpc_name
}

${% if values.provision_gce %}
output "gce_internal_ip" {
  description = "GCE instance internal IP"
  value       = module.gce.internal_ip
}
${% endif %}

${% if values.provision_gcs %}
output "gcs_bucket_url" {
  description = "GCS bucket URL"
  value       = module.gcs.bucket_url
}
${% endif %}

${% if values.provision_cloud_sql %}
output "cloud_sql_connection_name" {
  description = "Cloud SQL connection name for Auth Proxy"
  value       = module.cloud_sql.connection_name
  sensitive   = true
}
${% endif %}
SKELEOF

echo "✅ skeleton/terraform/outputs.tf created"

cat > templates/gcp-infrastructure/skeleton/docs/infrastructure.md << 'SKELEOF'
# Infrastructure — ${{ values.client_name }} (${{ values.environment }}) — GCP

Generated by **Opt IT Backstage**.

## What Was Provisioned

| Resource | Status |
|---|---|
| VPC | ✅ Always provisioned |
| Firewall | ${% if values.provision_firewall %}✅ Provisioned${% else %}❌ Not selected${% endif %} |
| Compute Engine | ${% if values.provision_gce %}✅ Provisioned${% else %}❌ Not selected${% endif %} |
| Cloud Storage | ${% if values.provision_gcs %}✅ Provisioned${% else %}❌ Not selected${% endif %} |
| Cloud SQL | ${% if values.provision_cloud_sql %}✅ Provisioned${% else %}❌ Not selected${% endif %} |

## Configuration

| Setting | Value |
|---|---|
| Client | ${{ values.client_name }} |
| Environment | ${{ values.environment }} |
| GCP Project | ${{ values.project_id }} |
| Region | ${{ values.region }} |
| Zone | ${{ values.zone }} |

## How To Apply

```bash
# Authenticate first
gcloud auth application-default login

${% if values.provision_cloud_sql %}
# Set DB password
export TF_VAR_admin_password="your-secure-password"
${% endif %}

cd terraform/
terraform init
terraform plan
terraform apply
```

## Managed By

This infrastructure is managed by **Opt IT Technologies** via Backstage.
SKELEOF

echo "✅ skeleton/docs/infrastructure.md created"

cat > templates/gcp-infrastructure/README.md << 'EOF'
# GCP Infrastructure Template

Backstage scaffolder template that provisions GCP infrastructure for Opt IT clients.

## Module Versions Used

| Module | Version |
|---|---|
| terraform-gcp-vpc | v1.0.0 |
| terraform-gcp-firewall | v1.0.0 |
| terraform-gcp-gce | v1.0.0 |
| terraform-gcp-gcs | v1.0.0 |
| terraform-gcp-cloud-sql | v1.0.0 |

## Phase

Phase 2b — GCP Infrastructure.
EOF

# Update root catalog-info.yaml to include GCP template
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
EOF

echo "✅ catalog-info.yaml updated with gcp-infrastructure"

echo ""
echo "================================================================"
echo "  Committing and pushing..."
echo "================================================================"

git add .
git commit -m "feat(gcp-infrastructure): add GCP infrastructure template v1.0.0"
git push origin main

echo ""
echo "================================================================"
echo "  ✅ GCP Infrastructure template pushed!"
echo ""
echo "  Next steps:"
echo "  1. Copy GcpResourcePicker.tsx to packages/app/src/components/GcpResourcePicker/"
echo "  2. Copy index.ts to packages/app/src/components/GcpResourcePicker/"
echo "  3. Add GcpResourcePickerFieldExtension to App.tsx"
echo "  4. Restart Backstage — yarn dev"
echo "================================================================"