# FILENAME: Macro Server File
# FILEPATH: src/modules/server/macro.tf

# Image

data "oci_core_images" "oracle_linux_10" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "10"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Compute Instance

resource "oci_core_instance" "macro" {
  count = var.macro_count

  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domain.ad.name
  fault_domain        = data.oci_identity_fault_domains.fds.fault_domains[count.index % length(data.oci_identity_fault_domains.fds.fault_domains)].name
  display_name        = "${var.prefix}-macro-${count.index + 1}"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = var.macro_ocpus
    memory_in_gbs = var.macro_ram_in_gbs
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.oracle_linux_10.images[0].id
    boot_volume_size_in_gbs = local.macro_boot_gbs
  }

  lifecycle {
    precondition {
      condition     = var.macro_count * var.macro_ocpus <= local.free_arm_ocpus
      error_message = "Arm OCPU request (${var.macro_count} x ${var.macro_ocpus} = ${var.macro_count * var.macro_ocpus}) exceeds the ${local.free_arm_ocpus}-OCPU OCI Always Free A1.Flex pool."
    }
    precondition {
      condition     = var.macro_count * var.macro_ram_in_gbs <= local.free_arm_ram
      error_message = "Arm memory request (${var.macro_count} x ${var.macro_ram_in_gbs} = ${var.macro_count * var.macro_ram_in_gbs}GB) exceeds the ${local.free_arm_ram}GB OCI Always Free A1.Flex pool."
    }
    precondition {
      condition     = local.total_boot_gbs <= local.free_block_storage_gbs
      error_message = "Total boot-volume storage (${local.total_boot_gbs}GB) exceeds the ${local.free_block_storage_gbs}GB OCI Always Free block-storage cap."
    }
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    display_name     = "${var.prefix}-macro-${count.index + 1}-vnic"
    hostname_label   = "${var.prefix}-macro-${count.index + 1}"
    assign_public_ip = true
  }

  agent_config {
    is_management_disabled = false
    is_monitoring_disabled = false

    plugins_config {
      name          = "Block Volume Management"
      desired_state = "ENABLED"
    }

    plugins_config {
      name          = "Compute Instance Monitoring"
      desired_state = "ENABLED"
    }

    plugins_config {
      name          = "Compute Instance Run Command"
      desired_state = "ENABLED"
    }

    plugins_config {
      name          = "Vulnerability Scanning"
      desired_state = "ENABLED"
    }
  }

  metadata = {
    ssh_authorized_keys = join("\n", var.opc_keys)
    user_data           = base64encode(file("${path.module}/scripts/server-init.sh"))
  }
}
