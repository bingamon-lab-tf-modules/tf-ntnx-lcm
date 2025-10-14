##################################################
# Prism Central
##################################################

# LCM configuration for Prism Central (optional)
variable "prism_central" {
  description = "Prism Central configuration for LCM actions."
  type = object({
    # General & Actions
    perform_inventory = optional(bool, false) # Whether to perform an inventory scan.
    perform_prechecks = optional(bool, false) # Whether to perform upgrade pre-checks.
    perform_upgrade   = optional(bool, false) # Whether to perform the upgrade.

    # LCM Configuration for Prism Central
    connectivity_type               = optional(string, "INTERNET")
    darksite_url                    = optional(string, null)
    is_auto_inventory_enabled       = optional(bool, true)
    auto_inventory_schedule         = optional(string, "00:00")
    is_https_enabled                = optional(bool, true)
    has_module_auto_upgrade_enabled = optional(bool, false)

    # The entities to upgrade
    entities_to_upgrade = optional(map(object({
      entity_model   = string
      target_version = optional(string, "latest")
      })), {
      "AOS" = {
        entity_model   = "AOS"
        target_version = "latest" # Example current: "7.0.1.6", target_version: "7.0.1.7"
      },
      "Epsilon" = {
        entity_model   = "Epsilon"
        target_version = "latest" # Example current: "4.1.1", target_version: "4.1.2"
      },
      "Files Manager" = {
        entity_model   = "Files Manager"
        target_version = "latest" # Example current: "5.2", target_version: "5.3"
      },
      "Licensing" = {
        entity_model   = "Licensing"
        target_version = "latest" # Example current: "LM.2024.2.9" or "LM.2025.2", target_version: "LM.2025.2"
      },
      "MSP" = {
        entity_model   = "MSP"
        target_version = "latest" # Example current: "2.6.1.5", target_version: "2.6.1.5"
      },
      "NCC" = {
        entity_model   = "NCC"
        target_version = "latest" # Example current: "5.2.0.1" or "5.2.0", target_version: "5.2.0.1"
      },
      "Network Controller" = {
        entity_model   = "Network Controller"
        target_version = "latest" # Example current: "5.0.0", target_version: "5.0.1"
      },
      "Objects Manager" = {
        entity_model   = "Objects Manager"
        target_version = "latest" # Example current: "5.1.1.1", target_version: "5.1.1.2"
      },
      "PC" = {
        entity_model   = "PC"
        target_version = "latest" # Example current: "pc.2024.3.1.7", target_version: "pc.2024.3.1.8"
      }
      "PC Core Services" = {
        entity_model   = "PC Core Services"
        target_version = "latest" # Example current: "4.3.36", target_version: "4.3.37"
      },
      "Security Dashboard CVE Data" = {
        entity_model   = "Security Dashboard CVE Data"
        target_version = "latest" # Example current: "2025.08.1", target_version: "2025.08.2"
      },
      "Self Service" = {
        entity_model   = "Self Service"
        target_version = "latest" # Example current: "4.1.1", target_version: "4.1.2"
      }
    })

    # Pre-check & Upgrade flags
    skipped_precheck_flags = optional(list(string), [])
    auto_handle_flags      = optional(list(string), [])
    max_wait_time_in_secs  = optional(number, 3600)

    # Management Server for hypervisor upgrades (e.g., ESXi)
    management_server = optional(object({
      hypervisor_type = string
      ip              = string
      username        = string
      password        = string
    }), null)
  })
  default = {}

  # Always need at least one entity to upgrade
  validation {
    condition = alltrue([
      var.prism_central.perform_upgrade ? (length(var.prism_central.entities_to_upgrade) > 0) : true,
    ])
    error_message = "At least one entity must be specified in 'entities_to_upgrade' when 'perform_upgrade' is true."
  }

  validation {
    condition = var.prism_central.management_server != null ? (
      var.prism_central.management_server.ip != null &&
      var.prism_central.management_server.username != null &&
      var.prism_central.management_server.password != null &&
      var.prism_central.management_server.hypervisor_type != null
    ) : true
    error_message = "When 'management_server' is provided, its 'ip', 'username', 'password', and 'hypervisor_type' attributes are all required."
  }

  validation {
    condition = alltrue([
      var.prism_central.connectivity_type != null &&
      contains(["INTERNET", "DARKSITE_WEB_SERVER"], var.prism_central.connectivity_type)
    ])
    error_message = "Prism Central LCM config 'connectivity_type' must be one of 'INTERNET' or 'DARKSITE_WEB_SERVER'."
  }

  validation {
    condition = alltrue([
      var.prism_central.connectivity_type == "DARKSITE_WEB_SERVER" ? var.prism_central.darksite_url != null : true
    ])
    error_message = "Prism Central LCM config 'darksite_url' must be provided when 'connectivity_type' is 'DARKSITE_WEB_SERVER'."
  }

  # If 'perform_prechecks' or 'perform_upgrade' is true for Prism Central, 'perform_inventory' must also be true.
  validation {
    condition     = var.prism_central.perform_prechecks || var.prism_central.perform_upgrade ? var.prism_central.perform_inventory : true
    error_message = "If 'perform_prechecks' or 'perform_upgrade' is true for Prism Central, 'perform_inventory' must also be true."
  }
}

##################################################
# Prism Element
##################################################

# LCM configuration for Prism Element (optional)
variable "prism_element" {
  description = "A optional map of Nutanix cluster configurations for LCM actions."
  type = map(object({
    # General & Actions
    name              = string
    perform_inventory = optional(bool, false) # Whether to perform an inventory scan.
    perform_prechecks = optional(bool, false) # Whether to perform pre-checks.
    perform_upgrade   = optional(bool, false) # Whether to perform an upgrade.

    # LCM Configuration (per-cluster)
    connectivity_type               = optional(string, "INTERNET")
    darksite_url                    = optional(string, null)
    is_auto_inventory_enabled       = optional(bool, true)
    auto_inventory_schedule         = optional(string, "00:00")
    is_https_enabled                = optional(bool, true)
    has_module_auto_upgrade_enabled = optional(bool, false)

    # The entities to upgrade
    entities_to_upgrade = optional(map(object({
      entity_model   = string
      target_version = optional(string, "latest")
      })), {
      "AHV hypervisor" = {
        entity_model   = "AHV hypervisor"
        target_version = "latest" # Example current: "10.0.1.1", target_version: "10.0.1.2"
      },
      "AOS" = {
        entity_model   = "AOS"
        target_version = "latest" # Example current: "7.0.1.6", target_version: "7.0.1.7"
      },
      "FSM" = {
        entity_model   = "FSM"
        target_version = "latest" # Example current: "5.2" or "5.0.0.3", target_version: "5.2"
      },
      "Foundation" = {
        entity_model   = "Foundation"
        target_version = "latest" # Example current: "5.9.1", target_version: "5.9.2"
      },
      "Foundation Platforms" = {
        entity_model   = "Foundation Platforms"
        target_version = "latest" # Example current: "2.18.1", target_version: "2.18.2"
      },
      "Licensing" = {
        entity_model   = "Licensing"
        target_version = "latest" # Example current: "LM.2024.2.9" or "LM.2025.2", target_version: "LM.2024.2"
      },
      "NCC" = {
        entity_model   = "NCC"
        target_version = "latest" # Example current: "5.2.0.1" or "5.2.0", target_version: "5.2.0.1"
      },
      "Security AOS" = {
        entity_model   = "Security AOS"
        target_version = "latest" # Example current: "security_aos.2022.9", target_version: "security_aos.2023.1"
      }
    })

    # Pre-check & Upgrade flags
    skipped_precheck_flags = optional(list(string), [])
    auto_handle_flags      = optional(list(string), [])
    max_wait_time_in_secs  = optional(number, 3600)

    # Management Server for hypervisor upgrades (e.g., ESXi)
    management_server = optional(object({
      hypervisor_type = string
      ip              = string
      username        = string
      password        = string
    }), null)
  }))
  default = {}

  # Always need at least one entity to upgrade
  validation {
    condition = alltrue([
      for k, v in var.prism_element :
      v.perform_upgrade ? (length(v.entities_to_upgrade) > 0) : true
    ])
    error_message = "At least one entity must be specified in 'entities_to_upgrade' when 'perform_upgrade' is true."
  }

  validation {
    condition = alltrue([
      for k, v in var.prism_element :
      v.management_server != null ? (
        v.management_server.ip != null &&
        v.management_server.username != null &&
        v.management_server.password != null &&
        v.management_server.hypervisor_type != null
      ) : true
    ])
    error_message = "When 'management_server' is provided, its 'ip', 'username', 'password', and 'hypervisor_type' attributes are all required."
  }

  validation {
    condition = alltrue([
      for k, v in var.prism_element :
      contains(["INTERNET", "DARKSITE_WEB_SERVER"], v.connectivity_type)
    ])
    error_message = "Cluster LCM config 'connectivity_type' must be one of 'INTERNET' or 'DARKSITE_WEB_SERVER'."
  }

  validation {
    condition = alltrue([
      for k, v in var.prism_element :
      v.connectivity_type == "DARKSITE_WEB_SERVER" ? v.darksite_url != null : true
    ])
    error_message = "Cluster LCM config 'darksite_url' must be provided when 'connectivity_type' is 'DARKSITE_WEB_SERVER'."
  }

  # An inventory must be performed if prechecks or upgrade is being performed.
  validation {
    condition = alltrue([
      for k, v in var.prism_element :
      v.perform_prechecks || v.perform_upgrade ? v.perform_inventory : true
    ])
    error_message = "If 'perform_prechecks' or 'perform_upgrade' is true for a cluster, 'perform_inventory' must also be true."
  }
}
