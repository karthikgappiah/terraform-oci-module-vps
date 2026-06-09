# FILENAME: Main File
# FILEPATH: main.tf

# Availability and Fault Domains

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

data "oci_identity_fault_domains" "fds" {
  compartment_id      = var.tenancy_ocid
  availability_domain = data.oci_identity_availability_domain.ad.name
}

# Images

data "oci_core_images" "oracle_linux_10_arm" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "10"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_core_images" "oracle_linux_10_x86" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "10"
  shape                    = "VM.Standard.E2.1.Micro"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Macro Instances (A1.Flex, Arm)

resource "oci_core_instance" "macro" {
  count = var.macro_count

  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domain.ad.name
  fault_domain        = data.oci_identity_fault_domains.fds.fault_domains[count.index % length(data.oci_identity_fault_domains.fds.fault_domains)].name
  display_name        = "${var.prefix}-macro-${count.index + 1}"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = 2
    memory_in_gbs = 12
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.oracle_linux_10_arm.images[0].id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id        = var.public_subnet_id
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

# Micro Instances (E2.1.Micro, x86)

resource "oci_core_instance" "micro" {
  count = var.micro_count

  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domain.ad.name
  fault_domain        = data.oci_identity_fault_domains.fds.fault_domains[count.index % length(data.oci_identity_fault_domains.fds.fault_domains)].name
  display_name        = "${var.prefix}-micro-${count.index + 1}"
  shape               = "VM.Standard.E2.1.Micro" # fixed shape — no shape_config

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.oracle_linux_10_x86.images[0].id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id        = var.public_subnet_id
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
