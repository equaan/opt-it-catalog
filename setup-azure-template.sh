#!/bin/bash
# ================================================================
# Opt IT — Azure Infrastructure Template Setup
# Run from inside your opt-it-catalog directory:
#   cd opt-it-catalog
#   bash setup-azure-template.sh
# ================================================================

set -e

echo "================================================================"
echo "  Opt IT — Creating Azure Infrastructure Template"
echo "================================================================"

mkdir -p templates/azure-infrastructure/skeleton/terraform
mkdir -p templates/azure-infrastructure/skeleton/docs

# ────────────────────────────────────────────────────────────────
# CATALOG-INFO.YAML
# ────────────────────────────────────────────────────────────────

cat > templates/azure-infrastructure/catalog-info.yaml << 'EOF'
apiVersion: backstage.io/v1alpha1
kind: Location
metadata:
  name: azure-infrastructure-template
  description: Opt IT Azure Infrastructure Template
spec:
  targets:
    - ./template.yaml
EOF

# ────────────────────────────────────────────────────────────────
# TEMPLATE.YAML
# ────────────────────────────────────────────────────────────────

cat > templates/azure-infrastructure/template.yaml << 'EOF'
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: azure-infrastructure
  title: Azure Infrastructure Setup
  description: Provisions production-grade Azure infrastructure for a client using versioned Opt IT modules. Supports Terraform.
  tags:
    - azure
    - terraform
    - infrastructure
    - phase-2
spec:
  owner: devops
  type: infrastructure

  parameters:

    # ─────────────────────────────────────────
    # PAGE 1 — Client Information
    # ─────────────────────────────────────────
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
          enum:
            - dev
            - staging
            - prod
          enumNames:
            - Development
            - Staging
            - Production
          ui:widget: radio

        repoUrl:
          title: Client Repository
          type: string
          ui:field: RepoUrlPicker
          ui:options:
            allowedHosts:
              - github.com

    # ─────────────────────────────────────────
    # PAGE 2 — Azure Resource Selection
    # Uses AzureResourcePicker custom field extension
    # ─────────────────────────────────────────
    - title: Step 2 - Azure Resources
      required:
        - azure_resources
      properties:
        azure_resources:
          title: Azure Resources
          type: object
          description: Select Azure location, confirm credentials, and choose resources to provision
          ui:field: AzureResourcePicker
          ui:options:
            environment: ${{ parameters.environment }}

    # ─────────────────────────────────────────
    # PAGE 3 — CI/CD Selection
    # ─────────────────────────────────────────
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
                github_actions_workflows:
                  title: Select Workflows
                  type: array
                  items:
                    type: string
                    enum: [build, test, deploy]
                    enumNames: [Build, Test, Deploy]
                  uniqueItems: true
                  ui:widget: checkboxes
              required:
                - cicd_tool

  # ─────────────────────────────────────────
  # STEPS
  # ─────────────────────────────────────────
  steps:

    # ── RESOURCE GROUP ──────────────────────
    - id: fetch-resource-group
      name: Fetch Resource Group Module
      action: fetch:plain
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-azure-resource-group-v1.0.0/terraform/azure/base/resource-group
        targetPath: ./terraform/modules/resource-group

    # ── VNET ────────────────────────────────
    - id: fetch-vnet
      name: Fetch VNet Module
      if: ${{ parameters.azure_resources.resources and parameters.azure_resources.resources.includes('vnet') }}
      action: fetch:plain
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-azure-vnet-v1.0.0/terraform/azure/networking/vnet
        targetPath: ./terraform/modules/vnet

    # ── NSG ─────────────────────────────────
    - id: fetch-nsg
      name: Fetch NSG Module
      if: ${{ parameters.azure_resources.resources and parameters.azure_resources.resources.includes('nsg') }}
      action: fetch:plain
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-azure-nsg-v1.0.0/terraform/azure/networking/nsg
        targetPath: ./terraform/modules/nsg

    # ── VM ──────────────────────────────────
    - id: fetch-vm
      name: Fetch VM Module
      if: ${{ parameters.azure_resources.resources and parameters.azure_resources.resources.includes('vm') }}
      action: fetch:plain
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-azure-vm-v1.0.0/terraform/azure/compute/vm
        targetPath: ./terraform/modules/vm

    # ── BLOB STORAGE ────────────────────────
    - id: fetch-blob
      name: Fetch Blob Storage Module
      if: ${{ parameters.azure_resources.resources and parameters.azure_resources.resources.includes('blob') }}
      action: fetch:plain
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-azure-blob-storage-v1.0.0/terraform/azure/storage/blob
        targetPath: ./terraform/modules/blob-storage

    # ── SQL FLEXIBLE ────────────────────────
    - id: fetch-sql
      name: Fetch SQL Flexible Server Module
      if: ${{ parameters.azure_resources.resources and parameters.azure_resources.resources.includes('sql') }}
      action: fetch:plain
      input:
        url: https://github.com/equaan/opt-it-modules/tree/terraform-azure-sql-flexible-v1.0.0/terraform/azure/database/sql-flexible
        targetPath: ./terraform/modules/sql-flexible

    # ── ROOT TERRAFORM ──────────────────────
    - id: generate-terraform-root
      name: Generate Terraform Root Configuration
      action: fetch:template
      input:
        url: https://github.com/equaan/opt-it-catalog/tree/main/templates/azure-infrastructure/skeleton/terraform
        targetPath: ./terraform
        values:
          client_name:               ${{ parameters.client_name }}
          environment:               ${{ parameters.environment }}
          location:                  ${{ parameters.azure_resources.foundation.location }}
          resource_group_suffix:     ${{ parameters.azure_resources.foundation.resource_group_suffix }}
          provision_vnet:            ${{ parameters.azure_resources.resources and parameters.azure_resources.resources.includes('vnet') }}
          provision_nsg:             ${{ parameters.azure_resources.resources and parameters.azure_resources.resources.includes('nsg') }}
          provision_vm:              ${{ parameters.azure_resources.resources and parameters.azure_resources.resources.includes('vm') }}
          provision_blob:            ${{ parameters.azure_resources.resources and parameters.azure_resources.resources.includes('blob') }}
          provision_sql:             ${{ parameters.azure_resources.resources and parameters.azure_resources.resources.includes('sql') }}
          vnet_address_space:        ${{ parameters.azure_resources.config.vnet_address_space }}
          public_subnet_prefixes:    ${{ parameters.azure_resources.config.public_subnet_prefixes }}
          private_subnet_prefixes:   ${{ parameters.azure_resources.config.private_subnet_prefixes }}
          enable_nat_gateway:        ${{ parameters.azure_resources.config.enable_nat_gateway }}
          allowed_ssh_source:        ${{ parameters.azure_resources.config.allowed_ssh_source_prefixes }}
          db_port:                   ${{ parameters.azure_resources.config.db_port }}
          vm_size:                   ${{ parameters.azure_resources.config.vm_size }}
          admin_username:            ${{ parameters.azure_resources.config.admin_username }}
          storage_suffix:            ${{ parameters.azure_resources.config.storage_suffix }}
          replication_type:          ${{ parameters.azure_resources.config.account_replication_type }}
          container_names:           ${{ parameters.azure_resources.config.container_names }}
          db_engine:                 ${{ parameters.azure_resources.config.db_engine }}
          db_version:                ${{ parameters.azure_resources.config.db_version }}
          sku_name:                  ${{ parameters.azure_resources.config.sku_name }}
          ha_mode:                   ${{ parameters.azure_resources.config.high_availability_mode }}

    # ── CI/CD ──────────────────────────────
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

    # ── PUBLISH PR ─────────────────────────
    - id: publish-pr
      name: Open Pull Request on Client Repository
      action: publish:github:pull-request
      input:
        repoUrl: ${{ parameters.repoUrl }}
        branchName: infra/${{ parameters.client_name }}-${{ parameters.environment }}-azure-${{ parameters.azure_resources.resources or 'setup' }}
        targetBranchName: main
        update: true
        title: "feat(infra): provision Azure ${{ parameters.environment }} infrastructure for ${{ parameters.client_name }}"
        description: |
          ## Azure Infrastructure Onboarding 🚀

          Provisioned by **Opt IT Backstage** — do not edit these files manually.

          ### Configuration Summary

          | Field | Value |
          |---|---|
          | **Client** | ${{ parameters.client_name }} |
          | **Environment** | ${{ parameters.environment }} |
          | **Azure Location** | ${{ parameters.azure_resources.foundation.location }} |
          | **Resources** | ${{ parameters.azure_resources.resources }} |
          | **CI/CD** | ${{ parameters.cicd_tool or 'none' }} |

          ### Next Steps

          1. Review all configuration values
          2. Ensure `ARM_SUBSCRIPTION_ID`, `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID` are set
          3. Set `TF_VAR_admin_password` if SQL was selected
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

# ────────────────────────────────────────────────────────────────
# SKELETON — main.tf
# ────────────────────────────────────────────────────────────────

cat > templates/azure-infrastructure/skeleton/terraform/main.tf << 'SKELEOF'
# ================================================================
# ${{ values.client_name }} — ${{ values.environment }} — Azure Infrastructure
# Generated by Opt IT Backstage
# DO NOT EDIT MANUALLY
# ================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Uncomment to configure remote state:
  # backend "azurerm" {
  #   resource_group_name  = "tfstate-rg"
  #   storage_account_name = "tfstate${{ values.client_name | replace('-', '') }}"
  #   container_name       = "tfstate"
  #   key                  = "${{ values.client_name }}-${{ values.environment }}.tfstate"
  # }
}

# ────────────────────────────────────────────────────────────────
# RESOURCE GROUP — always provisioned
# ────────────────────────────────────────────────────────────────

module "resource_group" {
  source = "./modules/resource-group"

  client_name           = var.client_name
  environment           = var.environment
  module_version        = "1.0.0"
  location              = var.location
  subscription_id       = var.subscription_id
  resource_group_suffix = "${{ values.resource_group_suffix }}"
}

# ────────────────────────────────────────────────────────────────
# VNET
# ${% if values.provision_vnet %}Provisioned${% else %}Not selected${% endif %}
# ────────────────────────────────────────────────────────────────

${% if values.provision_vnet %}
module "vnet" {
  source = "./modules/vnet"

  client_name             = var.client_name
  environment             = var.environment
  module_version          = "1.0.0"
  location                = module.resource_group.location
  subscription_id         = var.subscription_id
  resource_group_name     = module.resource_group.resource_group_name
  vnet_address_space      = [var.vnet_address_space]
  public_subnet_prefixes  = split(",", var.public_subnet_prefixes)
  private_subnet_prefixes = split(",", var.private_subnet_prefixes)
  enable_nat_gateway      = ${{ values.enable_nat_gateway }}
}
${% endif %}

# ────────────────────────────────────────────────────────────────
# NSG
# ${% if values.provision_nsg %}Provisioned${% else %}Not selected${% endif %}
# ────────────────────────────────────────────────────────────────

${% if values.provision_nsg %}
module "nsg" {
  source = "./modules/nsg"

  client_name                   = var.client_name
  environment                   = var.environment
  module_version                = "1.0.0"
  location                      = module.resource_group.location
  subscription_id               = var.subscription_id
  resource_group_name           = module.resource_group.resource_group_name
  public_subnet_ids             = module.vnet.public_subnet_ids
  private_subnet_ids            = module.vnet.private_subnet_ids
  allowed_ssh_source_prefixes   = var.allowed_ssh_source != "" ? split(",", var.allowed_ssh_source) : []
  db_port                       = var.db_port
}
${% endif %}

# ────────────────────────────────────────────────────────────────
# VM
# ${% if values.provision_vm %}Provisioned${% else %}Not selected${% endif %}
# ────────────────────────────────────────────────────────────────

${% if values.provision_vm %}
module "vm" {
  source = "./modules/vm"

  client_name         = var.client_name
  environment         = var.environment
  module_version      = "1.0.0"
  location            = module.resource_group.location
  subscription_id     = var.subscription_id
  resource_group_name = module.resource_group.resource_group_name
  subnet_id           = module.vnet.private_subnet_ids[0]
  vm_size             = var.vm_size
  admin_username      = var.admin_username
}
${% endif %}

# ────────────────────────────────────────────────────────────────
# BLOB STORAGE
# ${% if values.provision_blob %}Provisioned${% else %}Not selected${% endif %}
# ────────────────────────────────────────────────────────────────

${% if values.provision_blob %}
module "blob_storage" {
  source = "./modules/blob-storage"

  client_name              = var.client_name
  environment              = var.environment
  module_version           = "1.0.0"
  location                 = module.resource_group.location
  subscription_id          = var.subscription_id
  resource_group_name      = module.resource_group.resource_group_name
  storage_suffix           = var.storage_suffix
  account_replication_type = var.replication_type
  container_names          = split(",", var.container_names)
}
${% endif %}

# ────────────────────────────────────────────────────────────────
# SQL FLEXIBLE SERVER
# ${% if values.provision_sql %}Provisioned${% else %}Not selected${% endif %}
# ────────────────────────────────────────────────────────────────

${% if values.provision_sql %}
resource "azurerm_private_dns_zone" "sql" {
  name                = "${{ values.client_name }}-${{ values.environment }}.${var.db_engine == "postgres" ? "postgres" : "mysql"}.database.azure.com"
  resource_group_name = module.resource_group.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "${{ values.client_name }}-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  resource_group_name   = module.resource_group.resource_group_name
  virtual_network_id    = module.vnet.vnet_id
}

module "sql" {
  source = "./modules/sql-flexible"

  client_name            = var.client_name
  environment            = var.environment
  module_version         = "1.0.0"
  location               = module.resource_group.location
  subscription_id        = var.subscription_id
  resource_group_name    = module.resource_group.resource_group_name
  delegated_subnet_id    = module.vnet.private_subnet_ids[1]
  private_dns_zone_id    = azurerm_private_dns_zone.sql.id
  db_engine              = var.db_engine
  db_version             = var.db_version
  sku_name               = var.sku_name
  admin_username         = var.admin_username
  admin_password         = var.admin_password
  high_availability_mode = var.ha_mode
}
${% endif %}
SKELEOF

echo "✅ skeleton/terraform/main.tf created"

# ────────────────────────────────────────────────────────────────
# SKELETON — variables.tf
# ────────────────────────────────────────────────────────────────

cat > templates/azure-infrastructure/skeleton/terraform/variables.tf << 'SKELEOF'
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

variable "location" {
  type    = string
  default = "${{ values.location }}"
}

variable "subscription_id" {
  type      = string
  sensitive = true
  # Set via: export TF_VAR_subscription_id=$ARM_SUBSCRIPTION_ID
}

${% if values.provision_vnet %}
variable "vnet_address_space" {
  type    = string
  default = "${{ values.vnet_address_space }}"
}

variable "public_subnet_prefixes" {
  type    = string
  default = "${{ values.public_subnet_prefixes }}"
}

variable "private_subnet_prefixes" {
  type    = string
  default = "${{ values.private_subnet_prefixes }}"
}
${% endif %}

${% if values.provision_nsg %}
variable "allowed_ssh_source" {
  type    = string
  default = "${{ values.allowed_ssh_source }}"
}

variable "db_port" {
  type    = number
  default = ${{ values.db_port }}
}
${% endif %}

${% if values.provision_vm %}
variable "vm_size" {
  type    = string
  default = "${{ values.vm_size }}"
}

variable "admin_username" {
  type    = string
  default = "${{ values.admin_username }}"
}
${% endif %}

${% if values.provision_blob %}
variable "storage_suffix" {
  type    = string
  default = "${{ values.storage_suffix }}"
}

variable "replication_type" {
  type    = string
  default = "${{ values.replication_type }}"
}

variable "container_names" {
  type    = string
  default = "${{ values.container_names }}"
}
${% endif %}

${% if values.provision_sql %}
variable "db_engine" {
  type    = string
  default = "${{ values.db_engine }}"
}

variable "db_version" {
  type    = string
  default = "${{ values.db_version }}"
}

variable "sku_name" {
  type    = string
  default = "${{ values.sku_name }}"
}

variable "ha_mode" {
  type    = string
  default = "${{ values.ha_mode }}"
}

variable "admin_password" {
  type      = string
  sensitive = true
  # Set via: export TF_VAR_admin_password="your-password"
}
${% endif %}
SKELEOF

echo "✅ skeleton/terraform/variables.tf created"

# ────────────────────────────────────────────────────────────────
# SKELETON — outputs.tf
# ────────────────────────────────────────────────────────────────

cat > templates/azure-infrastructure/skeleton/terraform/outputs.tf << 'SKELEOF'
# ================================================================
# ${{ values.client_name }} — ${{ values.environment }} — Outputs
# Generated by Opt IT Backstage — DO NOT EDIT MANUALLY
# ================================================================

output "resource_group_name" {
  description = "Resource group name"
  value       = module.resource_group.resource_group_name
}

output "location" {
  description = "Azure location"
  value       = module.resource_group.location
}

${% if values.provision_vnet %}
output "vnet_id" {
  description = "VNet ID"
  value       = module.vnet.vnet_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vnet.private_subnet_ids
}
${% endif %}

${% if values.provision_vm %}
output "vm_private_ip" {
  description = "VM private IP address"
  value       = module.vm.private_ip_address
}
${% endif %}

${% if values.provision_blob %}
output "storage_account_name" {
  description = "Storage account name"
  value       = module.blob_storage.storage_account_name
}
${% endif %}

${% if values.provision_sql %}
output "sql_server_fqdn" {
  description = "SQL server FQDN — use as host in connection strings"
  value       = module.sql.server_fqdn
  sensitive   = true
}
${% endif %}
SKELEOF

echo "✅ skeleton/terraform/outputs.tf created"

# ────────────────────────────────────────────────────────────────
# SKELETON — docs
# ────────────────────────────────────────────────────────────────

cat > templates/azure-infrastructure/skeleton/docs/infrastructure.md << 'SKELEOF'
# Infrastructure — ${{ values.client_name }} (${{ values.environment }}) — Azure

Generated by **Opt IT Backstage**.

## What Was Provisioned

| Resource | Status |
|---|---|
| Resource Group | ✅ Always provisioned |
| VNet | ${% if values.provision_vnet %}✅ Provisioned${% else %}❌ Not selected${% endif %} |
| NSG | ${% if values.provision_nsg %}✅ Provisioned${% else %}❌ Not selected${% endif %} |
| VM | ${% if values.provision_vm %}✅ Provisioned${% else %}❌ Not selected${% endif %} |
| Blob Storage | ${% if values.provision_blob %}✅ Provisioned${% else %}❌ Not selected${% endif %} |
| SQL Flexible | ${% if values.provision_sql %}✅ Provisioned${% else %}❌ Not selected${% endif %} |

## Configuration

| Setting | Value |
|---|---|
| Client | ${{ values.client_name }} |
| Environment | ${{ values.environment }} |
| Azure Location | ${{ values.location }} |

## How To Apply

```bash
# Set required environment variables first
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_TENANT_ID="your-tenant-id"
export TF_VAR_subscription_id=$ARM_SUBSCRIPTION_ID

${% if values.provision_sql %}
export TF_VAR_admin_password="your-secure-db-password"
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

# ────────────────────────────────────────────────────────────────
# TEMPLATE README
# ────────────────────────────────────────────────────────────────

cat > templates/azure-infrastructure/README.md << 'EOF'
# Azure Infrastructure Template

Backstage scaffolder template that provisions production-grade Azure infrastructure for Opt IT clients.

## What It Does

1. Takes client name, environment as input
2. Lets the DevOps engineer select Azure location and resources via AzureResourcePicker
3. Fetches versioned Terraform modules from opt-it-modules
4. Generates a wired-together root main.tf, variables.tf, outputs.tf
5. Opens a PR on the client's GitHub repository

## Resources Supported

- Resource Group (always provisioned — Azure foundation)
- VNet + Subnets + NAT Gateway (networking)
- NSG (security groups on subnets)
- VM (Linux virtual machine)
- Blob Storage (storage account + containers)
- SQL Flexible Server (PostgreSQL or MySQL)

## Module Versions Used

| Module | Version |
|---|---|
| terraform-azure-resource-group | v1.0.0 |
| terraform-azure-vnet | v1.0.0 |
| terraform-azure-nsg | v1.0.0 |
| terraform-azure-vm | v1.0.0 |
| terraform-azure-blob-storage | v1.0.0 |
| terraform-azure-sql-flexible | v1.0.0 |

## Phase

Phase 2 — Azure Infrastructure.
EOF

echo "✅ README.md created"

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
EOF

echo "✅ catalog-info.yaml updated with azure-infrastructure"

# ────────────────────────────────────────────────────────────────
# COMMIT AND PUSH
# ────────────────────────────────────────────────────────────────

echo ""
echo "================================================================"
echo "  Committing and pushing..."
echo "================================================================"

git add .
git commit -m "feat(azure-infrastructure): add atomic Azure infrastructure template v1.0.0"
git push origin main

echo ""
echo "================================================================"
echo "  ✅ Azure Infrastructure template pushed!"
echo ""
echo "  Next steps:"
echo "  1. Copy AzureResourcePicker.tsx to packages/app/src/components/AzureResourcePicker/"
echo "  2. Copy index.ts to packages/app/src/components/AzureResourcePicker/"
echo "  3. Register AzureResourcePickerFieldExtension in App.tsx"
echo "  4. Restart Backstage — yarn dev"
echo "================================================================"