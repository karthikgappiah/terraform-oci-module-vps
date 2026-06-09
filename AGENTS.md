# AGENTS.md

Guidance for AI coding agents (Claude Code, Copilot, Cursor) working in this repo.

## What this is

A **child Terraform module** that provisions OCI Always Free compute (VPS). No root module — it is meant to be called by a root config.

## Commands

```bash
terraform fmt -recursive   # format
terraform validate         # validate
terraform plan / apply     # run from a root module that calls this one
```

## Architecture

Provisions two instance types in a single availability domain, each spread across fault domains via `count.index % fd_count`:

- **Macro** ([macro.tf](macro.tf)) — `VM.Standard.A1.Flex` Arm, Oracle Linux 10, configurable OCPU/RAM. Gets [scripts/server-init.sh](scripts/server-init.sh) via `user_data` (base64).
- **Micro** ([micro.tf](micro.tf)) — `VM.Standard.E2.1.Micro` x86, Oracle Linux 10, fixed shape. No startup script.

Conventions:
- **Always Free guard-rails** — `lifecycle.precondition` blocks enforce limits at plan time: 4 Arm OCPUs, 24 GB Arm RAM, 2 Micro instances, 200 GB total boot storage. Limits live as `local.free_*` in [main.tf](main.tf).
- **Boot volumes** — 50 GB each (`local.*_boot_gbs`), summed into `local.total_boot_gbs` for the storage cap.
- **Images** — latest Oracle Linux 10 resolved at plan time via `oci_core_images`, filtered by shape.
- **Versions** — Terraform `~> 1.15.0`, `oracle/oci` `~> 8.17.0` (see [versions.tf](versions.tf)).

## Inputs / Outputs

Canonical definitions live in [variables.tf](variables.tf) and [outputs.tf](outputs.tf); keep the README table in sync when they change. Required inputs: `compartment_id`, `tenancy_ocid`, `prefix`, `subnet_id`, `ad_number`, `opc_keys`, `macro_count`/`macro_ocpus`/`macro_ram_in_gbs`, `micro_count`.
