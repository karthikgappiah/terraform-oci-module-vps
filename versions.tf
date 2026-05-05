# FILENAME: Server Module Versions File
# FILEPATH: src/modules/server/versions.tf

terraform {
  required_version = "~> 1.15.0" # Permits 1.15.X versions only.

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 8.17.0" # Permits 8.17.X versions only
    }
  }
}
