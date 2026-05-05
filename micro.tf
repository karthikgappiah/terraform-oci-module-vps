# FILENAME: Micro Server File
# FILEPATH: src/modules/server/micro.tf

# Image

data "oci_core_images" "oracle_linux_10_x86" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "10"
  shape                    = "VM.Standard.E2.1.Micro"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Compute Instances

resource "oci_core_instance" "micro" {
  count = var.micro_count

  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domain.ad.name
  fault_domain        = data.oci_identity_fault_domains.fds.fault_domains[count.index % length(data.oci_identity_fault_domains.fds.fault_domains)].name
  display_name        = "${var.prefix}-micro-${count.index + 1}"
  shape               = "VM.Standard.E2.1.Micro"

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.oracle_linux_10_x86.images[0].id
    boot_volume_size_in_gbs = local.micro_boot_gbs
  }

  lifecycle {
    precondition {
      condition     = var.micro_count <= local.free_micro_count
      error_message = "Micro instance count (${var.micro_count}) exceeds the ${local.free_micro_count}-instance OCI Always Free E2.1.Micro grant."
    }
    precondition {
      condition     = local.total_boot_gbs <= local.free_block_storage_gbs
      error_message = "Total boot-volume storage (${local.total_boot_gbs}GB) exceeds the ${local.free_block_storage_gbs}GB OCI Always Free block-storage cap."
    }
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    display_name     = "${var.prefix}-micro-${count.index + 1}-vnic"
    hostname_label   = "${var.prefix}micro${count.index + 1}"
    assign_public_ip = true
  }

  agent_config {
    is_management_disabled = false
    is_monitoring_disabled = false

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
  }
}
