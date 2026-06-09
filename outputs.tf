# FILENAME: Outputs File
# FILEPATH: outputs.tf

output "macro_instance_ids" {
  description = "OCIDs of the A1.Flex (Arm) macro instances."
  value       = oci_core_instance.macro[*].id
}

output "micro_instance_ids" {
  description = "OCIDs of the E2.1.Micro (x86) micro instances."
  value       = oci_core_instance.micro[*].id
}

output "macro_public_ips" {
  description = "Public IPs of the macro instances."
  value       = oci_core_instance.macro[*].public_ip
}

output "micro_public_ips" {
  description = "Public IPs of the micro instances."
  value       = oci_core_instance.micro[*].public_ip
}
