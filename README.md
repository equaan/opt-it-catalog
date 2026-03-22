# opt-it-catalog

> Backstage scaffolder template catalog for Opt IT Technologies.

This repository contains all Backstage template YAML files and skeleton code used by the Opt IT internal developer platform. When a DevOps engineer uses Backstage to onboard a client, this is where the templates come from.

---

## Table of Contents

- [Repository Structure](#repository-structure)
- [How It Works](#how-it-works)
- [Available Templates](#available-templates)
- [Adding a New Template](#adding-a-new-template)
- [Understanding Skeleton Files](#understanding-skeleton-files)
- [Template YAML Reference](#template-yaml-reference)
- [Registering Templates in Backstage](#registering-templates-in-backstage)
- [Debugging a Failed Template Run](#debugging-a-failed-template-run)
- [Key Lessons Learned](#key-lessons-learned)
- [Common Mistakes To Avoid](#common-mistakes-to-avoid)

---

## Repository Structure

```
opt-it-catalog/
│
├── catalog-info.yaml                          ← registers all templates in Backstage
│
└── templates/
    ├── client-onboarding/                     ← Phase 5 ✅ — start here for new clients
    │   ├── template.yaml                      ← 7-step wizard combining all phases
    │   ├── catalog-info.yaml
    │   └── README.md
    │
    ├── aws-infrastructure/                    ← Phase 1 ✅
    │   ├── template.yaml                      ← Backstage scaffolder template
    │   ├── catalog-info.yaml                  ← individual template registration
    │   ├── README.md                          ← template documentation
    │   └── skeleton/                          ← files generated into client repo
    │       ├── terraform/
    │       │   ├── main.tf                    ← wires all modules together
    │       │   ├── variables.tf               ← pre-filled with form values
    │       │   └── outputs.tf                 ← outputs for selected resources
    │       └── docs/
    │           └── infrastructure.md          ← auto-generated infra docs
    │
    ├── azure-infrastructure/                  ← Phase 2 ✅
    │   ├── template.yaml
    │   ├── catalog-info.yaml
    │   ├── README.md
    │   └── skeleton/terraform/
    │
    ├── gcp-infrastructure/                    ← Phase 2b ✅
    │   ├── template.yaml
    │   ├── catalog-info.yaml
    │   ├── README.md
    │   └── skeleton/terraform/
    │
    ├── cicd-pipeline/                         ← Phase 3 ✅
    │   ├── template.yaml
    │   ├── catalog-info.yaml
    │   └── README.md
    │
    ├── observability-stack/                   ← Phase 3 ✅
    │   ├── template.yaml
    │   ├── catalog-info.yaml
    │   └── README.md
    │
    ├── security-scan/                         ← Phase 4 ✅
    │   ├── template.yaml
    │   ├── catalog-info.yaml
    │   └── README.md
    │
    └── container-setup/                       ← Phase 4 ✅
        ├── template.yaml
        ├── catalog-info.yaml
        └── README.md
```

---

## How It Works

```
DevOps engineer opens Backstage → clicks "Create"
        ↓
Backstage reads template.yaml from this repo
        ↓
Engineer fills the multi-step form
        ↓
Backstage runs the steps defined in template.yaml:
  → Fetches modules from opt-it-modules (pinned to git tags)
  → Renders skeleton files with form values (Nunjucks templating)
  → Opens a PR on the client's GitHub repository
        ↓
Client repo receives infrastructure code
        ↓
Engineer reviews PR and merges
        ↓
Client runs terraform init && terraform apply
```

---

## Available Templates

## ⭐ Start Here

### Full Client Onboarding (`templates/client-onboarding`)

The master template. For new client onboarding, always use this first.

Combines all phases into one 7-step guided wizard:

| Step | Section | What it sets up |
|---|---|---|
| 1 | Client Basics | Name, environment, repo |
| 2 | Cloud Infrastructure | AWS, Azure, or GCP — your choice |
| 3 | CI/CD Pipeline | GitHub Actions, Jenkins, GitLab CI, ArgoCD |
| 4 | Observability | Prometheus, Grafana, Alertmanager |
| 5 | Security Scanning | Trivy, OWASP Dependency Check |
| 6 | Containers | Dockerfile, Docker Compose, Kubernetes, Helm |
| 7 | Review + Create | One PR with everything |

**Output:** Single PR on client repo, branch `onboarding/{client}-{environment}`

### AWS Infrastructure (`templates/aws-infrastructure`)

**What it does:** Provisions production-grade AWS infrastructure for a client.

**Supported IaC tools:** Terraform, CloudFormation

**Supported resources:**
- VPC + Subnets + Security Groups (networking foundation)
- EC2 + IAM Baseline (compute)
- S3 (storage)
- RDS — MySQL or PostgreSQL (database)

**Supported CI/CD:** GitHub Actions, Jenkins

**How to use:**
1. Open Backstage at `http://localhost:3000/create`
2. Select **AWS Infrastructure Setup**
3. Fill in client name, environment, AWS region
4. Select IaC tool
5. Use the resource picker to select and configure AWS resources
6. Optionally add CI/CD
7. Submit — a PR will open on the client's repo

**What gets generated in the client repo:**
```
terraform/
├── main.tf           ← all selected modules wired together
├── variables.tf      ← pre-filled with your selections
├── outputs.tf        ← outputs for selected resources
└── modules/
    ├── vpc/          ← if VPC selected
    ├── subnets/      ← if VPC selected
    ├── security-groups/ ← if EC2 or RDS selected
    ├── ec2/          ← if EC2 selected
    ├── iam-baseline/ ← if EC2 selected
    ├── s3/           ← if S3 selected
    └── rds/          ← if RDS selected
docs/
└── infrastructure.md ← auto-generated infrastructure summary
```

### Azure Infrastructure (`templates/azure-infrastructure`)

**What it does:** Provisions production-grade Azure infrastructure for a client.

**Supported IaC tools:** Terraform

**Supported resources:**
- Resource Group (always provisioned — Azure foundation)
- VNet + Subnets + NAT Gateway (networking)
- NSG — Network Security Groups applied to subnets
- VM — Linux Virtual Machine with encrypted OS disk
- Blob Storage — Storage Account with private containers
- SQL Flexible Server — PostgreSQL or MySQL with private networking

**How to use:**
1. Open Backstage at `http://localhost:3000/create`
2. Select **Azure Infrastructure Setup**
3. Fill in client name and environment
4. Use the resource picker to select Azure location, confirm credentials, and choose resources
5. Optionally add CI/CD
6. Submit — a PR will open on the client's repo

**Prerequisites before running `terraform apply`:**
```bash
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_TENANT_ID="your-tenant-id"
export TF_VAR_subscription_id=$ARM_SUBSCRIPTION_ID
export TF_VAR_admin_password="your-db-password"  # only if SQL selected
```

**What gets generated in the client repo:**
```
terraform/
├── main.tf           ← all selected modules wired together
├── variables.tf      ← pre-filled with your selections
├── outputs.tf        ← outputs for selected resources
└── modules/
    ├── resource-group/   ← always present
    ├── vnet/             ← if VNet selected
    ├── nsg/              ← if NSG selected
    ├── vm/               ← if VM selected
    ├── blob-storage/     ← if Blob selected
    └── sql-flexible/     ← if SQL selected
docs/
└── infrastructure.md     ← auto-generated infrastructure summary
```

### GCP Infrastructure (`templates/gcp-infrastructure`)

**What it does:** Provisions production-grade GCP infrastructure for a client.

**Supported IaC tools:** Terraform

**Supported resources:**
- VPC — global VPC with regional public and private subnets
- Firewall — VPC-level rules using network tags
- Compute Engine — GCE VM with Shielded VM enabled
- Cloud Storage — GCS bucket with public access blocked
- Cloud SQL — PostgreSQL or MySQL with private IP

**Authentication:** Application Default Credentials (ADC)
```bash
gcloud auth application-default login
```

**Module versions:**

| Module | Version |
|---|---|
| terraform-gcp-vpc | v1.0.0 |
| terraform-gcp-firewall | v1.0.0 |
| terraform-gcp-gce | v1.0.0 |
| terraform-gcp-gcs | v1.0.0 |
| terraform-gcp-cloud-sql | v1.0.0 |

### CI/CD Pipeline (`templates/cicd-pipeline`)

Sets up CI/CD pipelines for a client repository.
Tools: GitHub Actions, Jenkins, GitLab CI, ArgoCD.
Multiple tools can be selected simultaneously.

| Tool | Type | Files generated |
|---|---|---|
| GitHub Actions | Push-based | `.github/workflows/build.yml`, `test.yml`, `deploy.yml` |
| Jenkins | Push-based | `Jenkinsfile` |
| GitLab CI | Push-based | `.gitlab-ci.yml` |
| ArgoCD | GitOps | `argocd/application.yaml`, `app-project.yaml`, `namespace.yaml` |

### Observability Stack (`templates/observability-stack`)

Sets up Prometheus + Grafana + Alertmanager.
Deployment: Docker Compose (single server) or Helm (Kubernetes).
Notifications: Slack webhook and/or email.

Alert rules included: CPU, memory, disk, instance down, HTTP error rate, latency, endpoint probe.

### Security Scan (`templates/security-scan`)

Adds Trivy and OWASP dependency scanning to a client repo.

Repository structure generated:
```
.github/workflows/
├── trivy-scan.yml         ← runs on every push + daily 2am UTC
└── dependency-check.yml   ← runs on push to main + weekly Monday 3am UTC
security/
├── trivy/
│   ├── trivy.yaml
│   └── .trivyignore
└── owasp/
    ├── dependency-check.yml
    └── suppressions.xml
```

Results upload to GitHub Security tab as SARIF.

### Container Setup (`templates/container-setup`)

Containerizes a client application.
Languages: Node.js, Python, Java, Go — all multi-stage builds with non-root users.

Repository structure generated:
```
containers/
├── dockerfiles/        ← Dockerfile.nodejs, .python, .java, .go
├── docker-compose/     ← local dev stack with optional DB and Redis
├── kubernetes/         ← Namespace, Deployment, Service, Ingress, HPA, ConfigMap, Secret
└── helm/               ← Helm chart with values.yaml and templates/
```

---

## Adding a New Template

Follow these steps every time you create a new template.

### Step 1 — Create the folder structure

```bash
mkdir -p templates/{template-name}/skeleton
```

### Step 2 — Create `template.yaml`

Every template must have:
- `metadata.name` — unique, lowercase, hyphenated
- `metadata.title` — human-readable name shown in Backstage
- `metadata.description` — what this template does
- `metadata.tags` — for filtering in the catalog
- `spec.owner` — `devops`
- `spec.type` — `infrastructure`, `cicd`, `service` etc.
- At least one `parameters` page
- At least one `steps` entry
- An `output.links` section showing the PR URL

### Step 3 — Create skeleton files

Skeleton files are Nunjucks templates rendered with values from the form. They go into the `skeleton/` folder and are fetched by the `generate-*` step in `template.yaml`.

Rules for skeleton files:
- Use `${{ values.variable_name }}` to insert form values
- Use `${% if values.condition %}...${% endif %}` for conditional blocks
- Never use `${{ "" | now }}` — Backstage Nunjucks does not support the `now` filter
- Keep skeleton files clean — no debug output, no commented-out blocks

### Step 4 — Create `catalog-info.yaml`

```yaml
apiVersion: backstage.io/v1alpha1
kind: Location
metadata:
  name: {template-name}-template
  description: Opt IT {Template Name} Template
spec:
  targets:
    - ./template.yaml
```

### Step 5 — Register in root `catalog-info.yaml`

Open `opt-it-catalog/catalog-info.yaml` and add your template:

```yaml
spec:
  targets:
    - ./templates/aws-infrastructure/template.yaml
    - ./templates/{your-new-template}/template.yaml   ← add this
```

### Step 6 — Create `README.md`

Every template folder must have a README covering:
- What the template does
- What resources it creates
- Which modules it uses and their versions
- What gets generated in the client repo
- How to add a new resource/service to the template

### Step 7 — Test end to end

Before pushing:
1. Restart Backstage — the template should appear in the catalog
2. Run the template against a test client repo
3. Check the PR on the client repo — does it have the right files?
4. Check the Backstage logs — are all steps passing?
5. Run `terraform plan` from the client repo — does it plan without errors?

---

## Understanding Skeleton Files

Skeleton files are the files that get generated into the client's repository. They use [Nunjucks](https://mozilla.github.io/nunjucks/) templating syntax.

### Variable Syntax

```nunjucks
${{ values.client_name }}        ← insert a value
${{ values.environment }}
```

### Conditional Blocks

```nunjucks
${% if values.provision_vpc %}
module "vpc" {
  source = "./modules/vpc"
  ...
}
${% endif %}
```

### What Values Are Available

Values come from the `generate-*` step in `template.yaml`:

```yaml
- id: generate-terraform-root
  action: fetch:template
  input:
    url: https://github.com/equaan/opt-it-catalog/tree/main/templates/aws-infrastructure/skeleton/terraform
    targetPath: ./terraform
    values:
      client_name:       ${{ parameters.client_name }}
      environment:       ${{ parameters.environment }}
      provision_vpc:     ${{ parameters.iac_resources.resources and parameters.iac_resources.resources.includes('vpc') }}
      vpc_cidr:          ${{ parameters.iac_resources.config.vpc_cidr }}
```

In skeleton files, these are accessed as `${{ values.client_name }}`, `${{ values.provision_vpc }}` etc.

### Nunjucks Limitations in Backstage

Backstage uses a sandboxed Nunjucks environment. These things do NOT work:
- `${{ "" | now }}` — no date/time filters
- `${{ range(10) }}` — no range function
- Importing external Nunjucks macros

---

## Template YAML Reference

### Parameters (Form Pages)

Each entry in `parameters` is one page of the form:

```yaml
parameters:
  - title: Step 1 - Client Information      ← page title shown in Backstage
    required:
      - client_name                          ← fields that must be filled
    properties:
      client_name:
        title: Client Name
        type: string
        description: "Example: acme-corp"
        ui:autofocus: true                   ← focus this field on load
```

### Conditional Fields

Use `oneOf` inside `dependencies` — this is the only reliable pattern in Backstage RJSF v4:

```yaml
dependencies:
  setup_cicd:
    oneOf:
      - properties:
          setup_cicd:
            enum: [false]           ← when false: show nothing extra

      - properties:
          setup_cicd:
            enum: [true]            ← when true: show cicd_tool
          cicd_tool:
            title: CI/CD Tool
            type: string
            enum: [github-actions, jenkins]
        required:
          - cicd_tool
```

### Custom Field Extensions

The pickers are custom React components registered in the Backstage app. Use them like this:

```yaml
iac_resources:
  title: AWS Resources
  type: object
  ui:field: AwsResourcePicker
  ui:options:
    environment: ${{ parameters.environment }}
```

Access values in steps as:
```yaml
${{ parameters.iac_resources.resources }}
${{ parameters.iac_resources.config.vpc_cidr }}
```

### Step If Conditions

Use `if:` to skip steps based on form values:

```yaml
- id: fetch-terraform-vpc
  if: ${{ parameters.iac_tool === 'terraform' and parameters.iac_resources.resources and parameters.iac_resources.resources.includes('vpc') }}
  action: fetch:template
  input:
    url: https://github.com/equaan/opt-it-modules/tree/terraform-aws-vpc-v1.0.0/terraform/aws/networking/vpc
    targetPath: ./terraform/modules/vpc
    values: {}
```

### Branch Naming

Always make branch names unique and avoid spaces or commas:

```yaml
branchName: infra/${{ parameters.client_name }}-${{ parameters.environment }}-setup
```

Always set `update: true` so re-runs update the existing PR instead of failing:

```yaml
update: true
```

---

## Registering Templates in Backstage

The root `catalog-info.yaml` at the top of this repo registers all templates. Backstage reads it via `app-config.yaml`.

### app-config.yaml entry (in backstage repo)

```yaml
catalog:
  locations:
    - type: url
      target: https://github.com/equaan/opt-it-catalog/blob/main/catalog-info.yaml
      rules:
        - allow: [Template]
```

### After adding a new template

1. Add it to `catalog-info.yaml` in this repo
2. Restart Backstage — or wait for the catalog refresh (every 30 minutes by default)
3. The template should appear at `http://localhost:3000/create`

---

## Debugging a Failed Template Run

### Where to find logs

In Backstage, go to: **Create → [your template run] → View logs**

Each step shows its status: `Finished`, `Skipping`, or the error.

### Common errors and fixes

| Error | Cause | Fix |
|---|---|---|
| `filter not found: now` | Used `${{ "" | now }}` in skeleton | Remove the filter — Backstage doesn't support it |
| `NotFoundError: 404` on fetch step | Tag doesn't exist on GitHub | Run `git tag -l` — create and push missing tag |
| `Pull request already exists` | Same branch name used twice | Add `update: true` to the PR step |
| `[object Object]` in branch name | Used whole object instead of `.resources` | Change to `parameters.iac_resources.resources` |
| `Git Repository is empty` | Client repo has no commits | Add a README to the client repo first |
| `if condition was false` unexpectedly | Parameter path is wrong | Log the parameter value — check nesting |
| Step skipped when it shouldn't be | Wrong `===` comparison | Verify the enum value matches exactly |
| Files missing from PR | Used `fetch:plain` instead of `fetch:template` | Change to `fetch:template` with `values: {}` |
| Branch name invalid ref error | Branch name contains spaces or commas | Use static suffix like `setup` instead of tool names |

### Checking what values were passed

In the step log, look for the line:
```
Processing N template files/directories with input values {...}
```

This shows exactly what values Backstage passed to the skeleton renderer. If a value is missing or wrong, the issue is in how it's passed from `parameters` to `values` in the step.

---

## Key Lessons Learned

These are hard-won lessons from building this platform. Read before making changes.

| Issue | Fix |
|---|---|
| Files not appearing in PR | Use `fetch:template` with `values: {}` — never `fetch:plain`. `fetch:plain` runs but Backstage does not commit the files to the PR |
| Branch name with spaces is invalid | Tool names like "GitLab CI" break Git refs — always use safe static suffixes like `setup` for branch names that include user-selected values |
| GCP modules not found | The directory is `terraform/GCP/` (capital) — all template URLs must match exactly. `terraform/gcp/` will silently fail |
| Template not refreshing in Backstage | Go to the catalog entity → three dots menu → Refresh. Or re-register at `/catalog-import`. Templates are cached and don't auto-reload on push |
| OWASP files landing in wrong folder | The OWASP source folder contained both the workflow yml and config xml. Split into `owasp/workflow/` and `owasp/config/` subfolders so each can be fetched independently to different `targetPath` values |
| `filter not found: now` in skeleton | Backstage Nunjucks does not support the `now` filter. Remove `${{ "" | now }}` from all skeleton files |
| `[object Object]` in branch name | `parameters.iac_resources` is an object — use `.resources` property, not the whole object |
| Cross-page dependencies | Backstage RJSF v4 cannot have `dependencies` that reference fields on a different page. Put controller and dependent fields on the same page |

---

## Common Mistakes To Avoid

**Using `${{ "" | now }}` in skeleton files**
Backstage Nunjucks does not have a `now` filter. Remove it.

**Pointing to `main` instead of a tag in fetch steps**
If the module changes, all future client onboardings get the new version silently. Always pin to a specific git tag.

**Cross-page dependencies**
Backstage RJSF v4 cannot have `dependencies` that reference fields on a different page. Put controller fields and their dependents on the same page.

**Not testing the PR on a real client repo**
Always run the template against a test client repo before shipping to production. The Backstage log only shows steps ran — it doesn't validate the generated Terraform is correct.

**Forgetting to register the template in `catalog-info.yaml`**
New templates won't appear in Backstage unless they're listed in the root `catalog-info.yaml`.

---

## Phase Roadmap

| Phase | Status | Template |
|---|---|---|
| Phase 1 | ✅ Complete | `aws-infrastructure` |
| Phase 2 | ✅ Complete | `azure-infrastructure` |
| Phase 2b | ✅ Complete | `gcp-infrastructure` |
| Phase 3 | ✅ Complete | `cicd-pipeline`, `observability-stack` |
| Phase 4 | ✅ Complete | `security-scan`, `container-setup` |
| Phase 5 | ✅ Complete | `client-onboarding` wizard |