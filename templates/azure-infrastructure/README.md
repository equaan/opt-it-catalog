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
