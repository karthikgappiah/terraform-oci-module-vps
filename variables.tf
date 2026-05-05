# FILENAME: Server Module Variables File
# FILEPATH: src/modules/server/variables.tf

variable "compartment_id" {
  description = "OCID of the compartment the instances are created in."
  type        = string
}

variable "tenancy_ocid" {
  description = "OCID of the OCI tenancy, used for image and domain data sources."
  type        = string
}

variable "prefix" {
  description = "Prefix applied to resource names."
  type        = string
}

variable "subnet_id" {
  description = "OCID of the subnet the instance VNICs attach to."
  type        = string
}

variable "ad_number" {
  description = "Availability domain number (1-based) to place the instances in."
  type        = number
}

variable "opc_keys" {
  description = "SSH public keys authorized for the opc user on the instances."
  type        = list(string)
}

variable "macro_count" {
  description = "Number of A1.Flex Arm instances to provision."
  type        = number
}

variable "macro_ocpus" {
  description = "OCPUs per A1.Flex instance."
  type        = number
}

variable "macro_ram_in_gbs" {
  description = "Memory in GB per A1.Flex instance."
  type        = number
}

variable "micro_count" {
  description = "Number of E2.1.Micro x86 instances to provision."
  type        = number
}
