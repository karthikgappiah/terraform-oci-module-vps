# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, Copilot, Cursor, etc.) when working with code in this repository.

## Overview

This is a **Terraform module** for provisioning OCI (Oracle Cloud Infrastructure) Always Free compute instances (VPS). It is designed to be consumed as a child module by a root Terraform configuration — it does not contain a root module itself.

## Common Commands

```bash
# Validate syntax and configuration
terraform validate

# Format all files
terraform fmt -recursive

# Plan (from a root module that calls this one)
terraform plan

# Apply
terraform apply
```

## Module Architecture

The module provisions two instance types within a single OCI availability domain:

- **Macro** ([macro.tf](macro.tf)): `VM.Standard.A1.Flex` Arm instances (Oracle Linux 10). Supports configurable OCPU/RAM. Spread across fault domains via `count.index % fd_count`.
- **Micro** ([micro.tf](micro.tf)): `VM.Standard.E2.1.Micro` x86 instances (Oracle Linux 10). Fixed shape, no configurable sizing.

Key design decisions:
- **Always Free guard-rails**: `lifecycle.precondition` blocks in both `macro.tf` and `micro.tf` enforce OCI Always Free limits (4 Arm OCPUs, 24 GB RAM, 2 Micro instances, 200 GB total block storage) at plan time.
- **Boot volume size**: Both instance types use 50 GB boot volumes, tracked via locals in [main.tf](main.tf) for the shared storage cap check.
- **Startup script**: Macro instances receive [scripts/server-init.sh](scripts/server-init.sh) via `user_data` (base64-encoded). Micro instances do not.
- **Image selection**: Both types query for the latest Oracle Linux 10 image at plan time via `oci_core_images` data sources filtered by shape.

## Required Inputs

| Variable | Description |
|---|---|
| `compartment_id` | OCID of the target compartment |
| `tenancy_ocid` | Tenancy OCID (used for image/domain data sources) |
| `prefix` | Name prefix for all resources |
| `subnet_id` | Subnet OCID for instance VNICs |
| `ad_number` | Availability domain number (1-based) |
| `opc_keys` | List of SSH public keys for the `opc` user |
| `macro_count` / `macro_ocpus` / `macro_ram_in_gbs` | A1.Flex sizing |
| `micro_count` | Number of E2.1.Micro instances |

## Provider & Version Constraints

- Terraform: `~> 1.15.0`
- OCI provider (`oracle/oci`): `~> 8.17.0`
