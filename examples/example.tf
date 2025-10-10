terraform {
  required_version = ">= 1.9.0"
}

module "tf-ntnx-lcm" {
  source = "git::https://github.com/bingamon-lab-tf-modules/tf-ntnx-lcm.git//module?ref=v1.0.0"

  clusters = {

    # Cluster 1 example (Internet connected)
    cluster-1 = {
      name = "cluster-1"

      # LCM Configuration
      connectivity_type               = "INTERNET"
      is_auto_inventory_enabled       = true
      auto_inventory_schedule         = "0 2 * * *" # Daily at 2 AM
      is_https_enabled                = true
      has_module_auto_upgrade_enabled = false

      # LCM Actions
      perform_inventory = true
      perform_prechecks = true
      perform_upgrade   = true
      target_version    = "2.0.0"
    }

    # Cluster 2 example (Dark site web server)
    cluster-2 = {
      name = "cluster-2"

      # LCM Configuration
      connectivity_type               = "DARKSITE_WEB_SERVER"
      darksite_url                    = "https://lcm.example.com"
      is_auto_inventory_enabled       = true
      auto_inventory_schedule         = "0 3 * * *" # Daily at 3 AM
      is_https_enabled                = true
      has_module_auto_upgrade_enabled = false

      # LCM Actions
      perform_inventory = true
      perform_prechecks = true
      perform_upgrade   = true
      target_version    = "2.0.0"
    }

    # Cluster 3 example (ESXi with management server)
    cluster-3 = {
      name = "cluster-3"

      # LCM Configuration
      connectivity_type               = "INTERNET"
      is_auto_inventory_enabled       = true
      auto_inventory_schedule         = "0 4 * * *" # Daily at 4 AM
      is_https_enabled                = true
      has_module_auto_upgrade_enabled = false

      # LCM Actions
      perform_inventory = true
      perform_prechecks = true
      perform_upgrade   = true
      target_version    = "2.0.0"

      # ESXi Management Server Configuration
      management_server = {
        hypervisor_type = "VMware"
        ip              = "192.168.1.100"
        username        = "administrator@vsphere.local"
        password        = "secure_password"
      }
    }

  }

}
