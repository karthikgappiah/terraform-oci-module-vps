# FILENAME: Server Module Outputs File
# FILEPATH: src/modules/server/outputs.tf

output "macro_instance_ids" {
  description = "OCIDs of the A1.Flex Arm instances."
  value       = oci_core_instance.macro[*].id
}

output "micro_instance_ids" {
  description = "OCIDs of the E2.1.Micro x86 instances."
  value       = oci_core_instance.micro[*].id
}

output "macro_public_ips" {
  description = "Public IPs of the A1.Flex Arm instances."
  value       = oci_core_instance.macro[*].public_ip
}

output "micro_public_ips" {
  description = "Public IPs of the E2.1.Micro x86 instances."
  value       = oci_core_instance.micro[*].public_ip
}
