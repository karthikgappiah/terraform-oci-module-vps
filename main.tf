# FILENAME: Server Module File
# FILEPATH: src/modules/server/main.tf

# Domains

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = var.ad_number
}

data "oci_identity_fault_domains" "fds" {
  compartment_id      = var.tenancy_ocid
  availability_domain = data.oci_identity_availability_domain.ad.name
}

# Local Variables

locals {
  macro_boot_gbs = 50
  micro_boot_gbs = 50

  free_arm_ocpus         = 4
  free_arm_ram           = 24
  free_micro_count       = 2
  free_block_storage_gbs = 200

  total_boot_gbs = (var.macro_count * local.macro_boot_gbs) + (var.micro_count * local.micro_boot_gbs)
}
