###################################
# Unit Tests: Prism Central
##################################################

#########################
# Provider
#########################

provider "nutanix" {
  username     = "dummy"
  password     = "dummy"
  endpoint     = "dummy.local"
  port         = 9440
  insecure     = true
  wait_timeout = 1
}

#########################
# Mock Data (Nutanix Provider)
#########################

mock_provider "nutanix" {

  # Prism Central cluster lookup
  mock_data "nutanix_clusters_v2" {
    defaults = {
      cluster_entities = [
        {
          ext_id                   = "00000000-0000-0000-0000-000000000000"
          name                     = "mock-prism-central-cluster"
          backup_eligibility_score = 0
          categories               = []
          cluster_profile_ext_id   = ""
          container_name           = ""
          expand                   = ""
          inefficient_vm_count     = 0
          links                    = []
          network                  = []
          nodes                    = []
          tenant_id                = ""
          upgrade_status           = ""
          vm_count                 = 0
          config = [
            {
              authorized_public_key_list       = []
              build_info                       = []
              cluster_arch                     = ""
              cluster_function                 = ["PRISM_CENTRAL"]
              cluster_software_map             = []
              encryption_in_transit_status     = ""
              encryption_option                = []
              encryption_scope                 = []
              fault_tolerance_state            = []
              hypervisor_types                 = ["AHV"]
              incarnation_id                   = 0
              is_available                     = true
              is_lts                           = false
              is_password_remote_login_enabled = false
              is_remote_support_enabled        = false
              operation_mode                   = ""
              pulse_status                     = []
              redundancy_factor                = 2
              timezone                         = ""
            }
          ]
        }
      ]
    }
  }

  # Prism Central entities lookup (empty response)
  mock_data "nutanix_lcm_entities_v2" {
    defaults = {
      entities = []
    }
  }

  # Prism Central entity lookup
  mock_data "nutanix_lcm_entity_v2" {
    defaults = {
      entity_model   = "mock"
      entity_version = "0.0.0"
    }
  }

  # Prism Central LCM status lookup
  mock_data "nutanix_lcm_status_v2" {
    defaults = {
      in_progress_operation = [
        {
          operation_type = ""
          operation_id   = ""
        }
      ]
    }
  }
}

#########################
# Mock Data (Local Provider)
#########################

mock_provider "local" {

  # Local file lookup
  mock_data "local_file" {
    defaults = {
      content = ""
    }
  }
}

#########################
# Tests
#########################

# Test 1: Empty configuration should work
run "prism_central_empty_config" {
  command = plan

  variables {
    prism_element = {}
    prism_central = {
      entities_to_upgrade = {}
    }
  }

  assert {
    condition     = output.lcm_entities_summary.prism_central.configured_count == 0
    error_message = "Expected 0 Prism Central entities"
  }
}

# Test 2: DarkSite without URL should fail
run "prism_central_darksite_without_url" {
  command = plan

  variables {
    prism_element = {}
    prism_central = {
      connectivity_type   = "DARKSITE_WEB_SERVER"
      darksite_url        = null
      entities_to_upgrade = {}
    }
  }

  expect_failures = [var.prism_central]
}

# Test 3: Prechecks without inventory should fail
run "prism_central_prechecks_without_inventory" {
  command = plan

  variables {
    prism_element = {}
    prism_central = {
      perform_inventory   = false
      perform_prechecks   = true
      entities_to_upgrade = {}
    }
  }

  expect_failures = [var.prism_central]
}

# Test 4: Upgrade without inventory should fail
run "prism_central_upgrade_without_inventory" {
  command = plan

  variables {
    prism_element = {}
    prism_central = {
      perform_inventory   = false
      perform_upgrade     = true
      entities_to_upgrade = {}
    }
  }

  expect_failures = [var.prism_central]
}

# Test 5: Invalid connectivity type should fail
run "prism_central_invalid_connectivity_type" {
  command = plan

  variables {
    prism_element = {}
    prism_central = {
      connectivity_type   = "INVALID"
      entities_to_upgrade = {}
    }
  }

  expect_failures = [var.prism_central]
}

# Test 6: Valid DarkSite configuration
run "prism_central_valid_darksite" {
  command = plan

  variables {
    prism_element = {}
    prism_central = {
      connectivity_type   = "DARKSITE_WEB_SERVER"
      darksite_url        = "https://darksite.local"
      entities_to_upgrade = {}
    }
  }

  assert {
    condition     = output.lcm_entities_summary.prism_central.configured_count == 0
    error_message = "Expected 0 entities for darksite"
  }
}

# Test 7: Valid upgrade configuration
run "prism_central_valid_upgrade" {
  command = plan

  variables {
    prism_element = {}
    prism_central = {
      perform_inventory = true
      perform_prechecks = true
      perform_upgrade   = true
      entities_to_upgrade = {
        "PC" = {
          entity_model   = "PC"
          target_version = "latest"
        }
      }
    }
  }

  assert {
    condition     = output.prism_central_entities_to_upgrade["PC"].entity_model == "PC"
    error_message = "Expected PC entity"
  }
}

# Test 8: Prism Central upgrade needs entities
run "prism_central_upgrade_needs_entities" {
  command = plan

  variables {
    prism_element = {}
    prism_central = {
      perform_inventory   = true
      perform_upgrade     = true
      entities_to_upgrade = {} # Invalid: needs at least one entity
    }
  }

  expect_failures = [var.prism_central]
}

# Test 9: Inventory options (inventory_type, node_list), sensitive management_server
# password, and v2.5.1 cluster network.management_server.type string schema.
run "prism_central_inventory_options_and_management_server" {
  command = plan

  variables {
    prism_element = {}
    prism_central = {
      perform_inventory = true
      inventory_type    = "NODE"
      node_list         = ["00000000-0000-0000-0000-000000000010"]
      perform_prechecks = true
      perform_upgrade   = true
      management_server = {
        hypervisor_type = "ESX"
        ip              = "192.0.2.50"
        username        = "administrator@vsphere.local"
        password        = "test-vcenter-secret"
      }
      entities_to_upgrade = {
        "PC" = {
          entity_model   = "PC"
          target_version = "latest"
        }
      }
    }
  }

  override_data {
    target = data.nutanix_clusters_v2.prism_central_cluster
    values = {
      cluster_entities = [
        {
          ext_id                   = "00000000-0000-0000-0000-000000000000"
          name                     = "mock-prism-central-cluster"
          backup_eligibility_score = 0
          categories               = []
          cluster_profile_ext_id   = ""
          container_name           = ""
          expand                   = ""
          inefficient_vm_count     = 0
          links                    = []
          network = [
            {
              backplane                  = null
              external_address           = null
              external_data_services_ip  = null
              external_subnet            = null
              fqdn                       = "pc.example.test"
              http_proxy_list            = null
              http_proxy_white_list      = null
              internal_subnet            = null
              key_management_server_type = null
              management_server = [
                {
                  ip             = null
                  is_drs_enabled = false
                  is_in_use      = true
                  is_registered  = true
                  type           = "VCENTER"
                }
              ]
              masquerading_ip       = null
              masquerading_port     = null
              name_server_ip_list   = null
              nfs_subnet_white_list = null
              ntp_server_ip_list    = null
              smtp_server           = null
            }
          ]
          nodes          = []
          tenant_id      = ""
          upgrade_status = ""
          vm_count       = 0
          config = [
            {
              authorized_public_key_list       = []
              build_info                       = []
              cluster_arch                     = ""
              cluster_function                 = ["PRISM_CENTRAL"]
              cluster_software_map             = []
              encryption_in_transit_status     = ""
              encryption_option                = []
              encryption_scope                 = []
              fault_tolerance_state            = []
              hypervisor_types                 = ["AHV"]
              incarnation_id                   = 0
              is_available                     = true
              is_lts                           = false
              is_password_remote_login_enabled = false
              is_remote_support_enabled        = false
              operation_mode                   = ""
              pulse_status                     = []
              redundancy_factor                = 2
              timezone                         = ""
            }
          ]
        }
      ]
    }
  }

  override_data {
    target = data.nutanix_lcm_entities_v2.prism_central_lcm_entities
    values = {
      entities = [
        {
          ext_id                        = "11111111-2222-3333-4444-555555555555"
          entity_model                  = "PC"
          entity_version                = "pc.2024.3.1.7"
          cluster_ext_id                = "00000000-0000-0000-0000-000000000000"
          device_id                     = ""
          tenant_id                     = ""
          entity_class                  = ""
          entity_type                   = ""
          entity_description            = ""
          entity_details                = []
          hardware_family               = ""
          hardware_vendor               = ""
          target_version                = ""
          last_updated_time             = ""
          group_uuid                    = ""
          has_previous_inventory_failed = false
          links                         = []
          location_info                 = []
          sub_entities                  = []
          child_entities                = []
          available_versions = [
            {
              version                = "pc.2024.3.1.8"
              order                  = 10
              status                 = "AVAILABLE"
              is_enabled             = true
              available_version_uuid = ""
              disablement_reason     = ""
              release_notes          = ""
              release_date           = ""
              custom_message         = ""
              child_entities         = []
              group_uuid             = ""
              dependencies           = []
            }
          ]
        }
      ]
    }
  }

  override_data {
    target = data.nutanix_lcm_entity_v2.prism_central_lcm_entities_after_upgrade
    values = {
      entity_model   = "PC"
      entity_version = "pc.2024.3.1.8"
    }
  }

  assert {
    condition     = output.lcm_entities_summary.prism_central.will_run_prechecks && output.lcm_entities_summary.prism_central.will_run_upgrade
    error_message = "Expected prechecks and upgrade to be planned for Prism Central PC entity"
  }

  assert {
    condition     = output.lcm_latest_version_by_entity["11111111-2222-3333-4444-555555555555"] == "pc.2024.3.1.8"
    error_message = "Expected PC latest version to resolve to pc.2024.3.1.8"
  }
}
