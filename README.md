# terraform-oci-module-vps

> Terraform module for provisioning [Oracle Cloud Infrastructure (OCI) Always Free](https://www.oracle.com/cloud/free/) compute instances (VPS).

[![Terraform](https://img.shields.io/badge/Terraform-%7E%3E%201.15.0-7B42BC?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![OCI Provider](https://img.shields.io/badge/oracle%2Foci-%7E%3E%208.17.0-F80000?logo=oracle&logoColor=white)](https://registry.terraform.io/providers/oracle/oci/latest)

This module provisions Arm (`A1.Flex`) and x86 (`E2.1.Micro`) compute instances within a single OCI availability domain, with built-in guard-rails that keep your usage inside the Always Free tier. It is a **child module** — call it from a root Terraform configuration that supplies the provider and networking.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Always Free Guard-Rails](#always-free-guard-rails)
- [Development](#development)

## Features

- **Two instance types** — Arm `VM.Standard.A1.Flex` (configurable OCPU/RAM) and x86 `VM.Standard.E2.1.Micro` (fixed shape).
- **Always Free guard-rails** — `lifecycle.precondition` blocks fail the plan before you exceed free-tier limits.
- **High availability** — instances are spread across fault domains automatically.
- **Latest OS images** — newest Oracle Linux 10 image is resolved at plan time per shape.
- **Cloud-init bootstrap** — Arm instances run [`scripts/server-init.sh`](scripts/server-init.sh) on first boot.
- **OCI agent plugins** — monitoring, run-command, and vulnerability scanning enabled out of the box.

## Architecture

| Concern | Macro ([macro.tf](macro.tf)) | Micro ([micro.tf](micro.tf)) |
|---|---|---|
| Shape | `VM.Standard.A1.Flex` (Arm) | `VM.Standard.E2.1.Micro` (x86) |
| OS | Oracle Linux 10 | Oracle Linux 10 |
| Sizing | Configurable OCPU / RAM | Fixed (1 OCPU / 1 GB) |
| Boot volume | 50 GB | 50 GB |
| Startup script | Yes (`user_data`) | No |
| Public IP | Yes | Yes |

Both types are placed in the availability domain named by `ad_number` and distributed across fault domains via `count.index % fd_count`. Shared locals in [main.tf](main.tf) track boot-volume totals for the storage cap check.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) `~> 1.15.0`
- An OCI tenancy with an [API signing key configured](https://docs.oracle.com/en-us/iaas/Content/dev/terraform/getting-started.htm) for the [`oracle/oci`](https://registry.terraform.io/providers/oracle/oci/latest) provider
- An existing VCN and **subnet** in the target compartment
- One or more SSH public keys for the `opc` user

## Usage

```hcl
module "vps" {
  source = "github.com/karthikgappiah/terraform-oci-module-vps"

  # Identity
  compartment_id = var.compartment_id
  tenancy_ocid   = var.tenancy_ocid
  prefix         = "demo"

  # Networking
  subnet_id = var.subnet_id
  ad_number = 1

  # Access
  opc_keys = [file("~/.ssh/id_ed25519.pub")]

  # Arm A1.Flex pool (max 4 OCPUs / 24 GB combined)
  macro_count      = 1
  macro_ocpus      = 4
  macro_ram_in_gbs = 24

  # x86 E2.1.Micro instances (max 2)
  micro_count = 2
}

output "macro_ips" {
  value = module.vps.macro_public_ips
}
```

Then:

```bash
terraform init
terraform plan
terraform apply
```

## Inputs

| Name | Description | Type | Required |
|---|---|---|:---:|
| `compartment_id` | OCID of the compartment the instances are created in. | `string` | yes |
| `tenancy_ocid` | Tenancy OCID, used for image and domain data sources. | `string` | yes |
| `prefix` | Prefix applied to resource names. | `string` | yes |
| `subnet_id` | OCID of the subnet the instance VNICs attach to. | `string` | yes |
| `ad_number` | Availability domain number (1-based). | `number` | yes |
| `opc_keys` | SSH public keys authorized for the `opc` user. | `list(string)` | yes |
| `macro_count` | Number of A1.Flex Arm instances. | `number` | yes |
| `macro_ocpus` | OCPUs per A1.Flex instance. | `number` | yes |
| `macro_ram_in_gbs` | Memory (GB) per A1.Flex instance. | `number` | yes |
| `micro_count` | Number of E2.1.Micro x86 instances. | `number` | yes |

## Outputs

| Name | Description |
|---|---|
| `macro_instance_ids` | OCIDs of the A1.Flex Arm instances. |
| `micro_instance_ids` | OCIDs of the E2.1.Micro x86 instances. |
| `macro_public_ips` | Public IPs of the A1.Flex Arm instances. |
| `micro_public_ips` | Public IPs of the E2.1.Micro x86 instances. |

## Always Free Guard-Rails

The module enforces these [OCI Always Free](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm) limits at **plan time** — exceeding any one fails the plan with a descriptive error rather than provisioning billable resources:

| Resource | Free-tier limit |
|---|---|
| Arm OCPUs | `macro_count × macro_ocpus ≤ 4` |
| Arm memory | `macro_count × macro_ram_in_gbs ≤ 24 GB` |
| Micro instances | `micro_count ≤ 2` |
| Total boot storage | `(macro_count + micro_count) × 50 GB ≤ 200 GB` |

## Development

```bash
terraform fmt -recursive   # format
terraform validate         # validate

terraform plan / apply     # run from a root module that calls this one
```

See [AGENTS.md](AGENTS.md) for module internals and contribution guidance.
