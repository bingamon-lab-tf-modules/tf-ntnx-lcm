terraform {

  required_version = ">= 1.9.0"

  required_providers {
    nutanix = {
      source  = "nutanix/nutanix"
      version = "2.3.4"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }

}
