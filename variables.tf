# FILENAME: Variables File
# FILEPATH: variables.tf

variable "compartment_id" {
  description = "OCID of the compartment to create instances in."
  type        = string
}

variable "tenancy_ocid" {
  description = "OCID of the tenancy, used to look up availability and fault domains."
  type        = string
}

variable "prefix" {
  description = "Prefix applied to resource names."
  type        = string
  default     = "my"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]*$", var.prefix)) && length(var.prefix) <= 9
    error_message = "prefix must be lowercase alphanumeric, start with a letter, and be at most 9 characters."
  }
}

variable "public_subnet_id" {
  description = "OCID of the public subnet to attach instances to."
  type        = string
}

variable "opc_keys" {
  description = "SSH public keys authorized for the opc user on all instances."
  type        = list(string)
}

variable "macro_count" {
  description = "Number of A1.Flex (Arm) instances. Total OCPUs across all instances must stay within the 4 OCPU / 24 GB always-free Arm pool."
  type        = number
  default     = 2
}

variable "micro_count" {
  description = "Number of E2.1.Micro (x86) instances. OCI grants 2 micros in the always-free tier."
  type        = number
  default     = 2
}
