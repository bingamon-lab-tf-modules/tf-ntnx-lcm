terraform {
  required_version = ">= 1.9.0"
}

module "lcm" {
  source = "git::https://github.com/bingamon-lab-tf-modules/tf-ntnx-lcm.git//module?ref=v0.1.1"

  ##################################################
  # Prism Central
  ##################################################

  # Internet-connected Prism Central that runs an inventory, pre-checks and
  # upgrade for a curated set of entities.
  prism_central = {
    connectivity_type = "INTERNET"

    perform_inventory = true
    perform_prechecks = true
    perform_upgrade   = true

    is_auto_inventory_enabled = true
    auto_inventory_schedule   = "02:00" # Daily at 02:00
    is_https_enabled          = true

    entities_to_upgrade = {
      "PC" = {
        entity_model   = "PC"
        target_version = "latest"
      }
      "AOS" = {
        entity_model   = "AOS"
        target_version = "latest"
      }
    }
  }

  ##################################################
  # Prism Element (one entry per cluster)
  ##################################################

  prism_element = {

    # Scenario 1: Internet-connected cluster.
    # Full inventory -> pre-checks -> upgrade flow against the public LCM feed.
    cluster-1 = {
      name = "cluster-1"

      connectivity_type = "INTERNET"

      perform_inventory = true
      perform_prechecks = true
      perform_upgrade   = true

      is_auto_inventory_enabled = true
      auto_inventory_schedule   = "02:00" # Daily at 02:00
      is_https_enabled          = true

      entities_to_upgrade = {
        "AOS" = {
          entity_model   = "AOS"
          target_version = "latest"
        }
      }
    }

    # Scenario 2: Dark-site cluster served by an internal LCM web server.
    # No outbound internet; `darksite_url` is required for this connectivity type.
    cluster-2 = {
      name = "cluster-2"

      connectivity_type = "DARKSITE_WEB_SERVER"
      darksite_url      = "https://lcm.example.com"

      perform_inventory = true
      perform_prechecks = true
      perform_upgrade   = false

      is_auto_inventory_enabled = true
      auto_inventory_schedule   = "03:00" # Daily at 03:00
      is_https_enabled          = true
    }

    # Scenario 3: ESXi cluster upgraded through a vCenter management server.
    # `management_server` is required so LCM can drive the hypervisor upgrade.
    cluster-3 = {
      name = "cluster-3"

      connectivity_type = "INTERNET"

      perform_inventory = true
      perform_prechecks = true
      perform_upgrade   = true

      is_auto_inventory_enabled = true
      auto_inventory_schedule   = "04:00" # Daily at 04:00
      is_https_enabled          = true

      entities_to_upgrade = {
        "AHV hypervisor" = {
          entity_model   = "AHV hypervisor"
          target_version = "latest"
        }
      }

      # Credentials for the hypervisor management server (e.g. vCenter for ESXi).
      # Source these from a secret manager in real deployments; shown inline here
      # only to illustrate the required attributes.
      management_server = {
        hypervisor_type = "VMware"
        ip              = "192.168.1.100"
        username        = "administrator@vsphere.local"
        password        = "changeme"
      }
    }
  }
}
