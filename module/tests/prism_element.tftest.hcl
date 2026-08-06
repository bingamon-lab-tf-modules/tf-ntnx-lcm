##################################################
# Unit Tests: Prism Element
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

  # Prism Element cluster lookup
  mock_data "nutanix_clusters_v2" {
    defaults = {
      cluster_entities = [
        {
          ext_id                   = "00000000-0000-0000-0000-000000000000"
          name                     = "mock-prism-element-cluster"
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
              cluster_function                 = ["AOS"]
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

  # Prism Element entities lookup (empty response)
  mock_data "nutanix_lcm_entities_v2" {
    defaults = {
      entities = []
    }
  }

  # Prism Element entity lookup.
  # ext_id is a required input on this data source, not a computed field, so it
  # cannot be mocked — doing so only went unnoticed while every test mocked an
  # empty entity list and this data source therefore had no instances.
  mock_data "nutanix_lcm_entity_v2" {
    defaults = {
      entity_model   = "mock"
      entity_version = "0.0.0"
    }
  }

  # Prism Element LCM status lookup
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
run "prism_element_empty_config" {
  command = plan

  variables {
    prism_element = {}
    prism_central = {}
  }

  assert {
    condition     = output.prism_element_summary.total_clusters == 0
    error_message = "Expected 0 Prism Element Clusters"
  }
}

# Test 2: DarkSite without URL should fail
run "prism_element_darksite_without_url" {
  command = plan

  variables {
    prism_element = {
      "test" = {
        name              = "test"
        connectivity_type = "DARKSITE_WEB_SERVER"
        darksite_url      = null
      }
    }
    prism_central = {}
  }

  expect_failures = [var.prism_element]
}

# Test 3: Prechecks without inventory should fail
run "prism_element_prechecks_without_inventory" {
  command = plan

  variables {
    prism_element = {
      "test" = {
        name              = "test"
        perform_inventory = false
        perform_prechecks = true
      }
    }
    prism_central = {}
  }

  expect_failures = [var.prism_element]
}

# Test 4: Upgrade without inventory should fail
run "prism_element_upgrade_without_inventory" {
  command = plan

  variables {
    prism_element = {
      "test" = {
        name              = "test"
        perform_inventory = false
        perform_upgrade   = true
      }
    }
    prism_central = {}
  }

  expect_failures = [var.prism_element]
}

# Test 5: Invalid connectivity type should fail
run "prism_element_invalid_connectivity_type" {
  command = plan

  variables {
    prism_element = {
      "test" = {
        name              = "test"
        connectivity_type = "INVALID"
      }
    }
    prism_central = {}
  }

  expect_failures = [var.prism_element]
}

# Test 6: Valid DarkSite configuration
run "prism_element_valid_darksite" {
  command = plan

  variables {
    prism_element = {
      "test" = {
        name              = "test"
        connectivity_type = "DARKSITE_WEB_SERVER"
        darksite_url      = "https://darksite.local"
      }
    }
    prism_central = {}
  }

  assert {
    condition     = output.prism_element_summary.total_clusters == 1
    error_message = "Expected 1 cluster"
  }
}

# Test 7: Valid upgrade configuration
run "prism_element_valid_upgrade" {
  command = plan

  variables {
    prism_element = {
      "test" = {
        name              = "test"
        perform_inventory = true
        perform_prechecks = true
        perform_upgrade   = true
      }
    }
    prism_central = {}
  }

  assert {
    condition     = output.prism_element_summary.upgrade_clusters == 1
    error_message = "Expected 1 upgrade cluster"
  }
}

# Test 8: Validate management server requires all fields
run "prism_element_cluster_management_server_incomplete" {
  command = plan

  variables {
    prism_element = {
      "test" = {
        name = "test"
        management_server = {
          hypervisor_type = "ESXi"
          ip              = "192.168.1.1"
          username        = "admin"
          password        = null
        }
      }
    }
    prism_central = {}
  }

  expect_failures = [var.prism_element]
}

# Test 9: Validate at least one entity required for upgrade
run "prism_element_cluster_upgrade_needs_entities" {
  command = plan

  variables {
    prism_element = {
      "test" = {
        name                = "test"
        perform_inventory   = true
        perform_upgrade     = true
        entities_to_upgrade = {} # Invalid: needs at least one entity
      }
    }
    prism_central = {}
  }

  expect_failures = [var.prism_element]
}

# Test 10: Multiple clusters with different configurations
run "prism_element_multiple_clusters" {
  command = plan

  variables {
    prism_element = {
      "test-1" = {
        name              = "test-1"
        connectivity_type = "INTERNET"
        perform_inventory = true
      }
      "test-2" = {
        name              = "test-2"
        connectivity_type = "DARKSITE_WEB_SERVER"
        darksite_url      = "https://darksite.example.com"
        perform_inventory = false
      }
      "test-3" = {
        name              = "test-3"
        perform_inventory = true
        perform_upgrade   = true
        entities_to_upgrade = {
          "AOS" = {
            entity_model   = "AOS"
            target_version = "latest"
          }
        }
      }
    }
    prism_central = {
      connectivity_type = "INTERNET"
    }
  }

  assert {
    condition     = output.prism_element_summary.total_clusters == 3
    error_message = "Expected 3 clusters"
  }

  assert {
    condition     = output.prism_element_summary.inventory_clusters == 2
    error_message = "Expected 2 inventory clusters"
  }

  assert {
    condition     = length(output.prism_element_summary.darksite_clusters) == 1
    error_message = "Expected 1 darksite cluster"
  }
}

# Test 11: "latest" resolves by the API's `order` field, not by list position.
#
# The LCM API returns available_versions unordered.
#
# NCC is here to cover the second half of the rule:
# the highest-ordered version is disabled, so it must not win.
run "prism_element_latest_resolves_by_order" {
  command = plan

  variables {
    prism_element = {
      "test" = {
        name              = "test"
        perform_inventory = true
        perform_prechecks = true
      }
    }
    prism_central = {}
  }

  override_data {
    target = data.nutanix_lcm_entities_v2.prism_element_lcm_entities
    values = {
      entities = [
        {
          ext_id         = "9bc0e3ec-d3f5-4244-967c-bac006498b08"
          entity_model   = "FSM"
          entity_version = "5.2.1"
          cluster_ext_id = "00000000-0000-0000-0000-000000000000"
          device_id      = ""

          # Scaffolding: overrides must supply every attribute of the schema.
          tenant_id          = ""
          entity_class       = ""
          entity_type        = ""
          entity_description = ""
          entity_details     = []
          hardware_family    = ""
          hardware_vendor    = ""
          target_version     = ""
          last_updated_time  = ""
          group_uuid         = ""
          links              = []
          location_info      = []
          sub_entities       = []
          child_entities     = []

          available_versions = [
            {
              version                = "5.3.0.2"
              order                  = 32
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
            },
            {
              version                = "5.3"
              order                  = 30
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
            },
            {
              version                = "5.3.0.3"
              order                  = 33
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
            },
            {
              version                = "5.3.0.1"
              order                  = 31
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
            },
            {
              version                = "5.2.1.2"
              order                  = 29
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
            },
          ]
        },
        {
          ext_id         = "8b1920c1-de2c-4b73-abc8-7f7ec086dba6"
          entity_model   = "NCC"
          entity_version = "5.3.1"
          cluster_ext_id = "00000000-0000-0000-0000-000000000000"
          device_id      = ""

          # Scaffolding: overrides must supply every attribute of the schema.
          tenant_id          = ""
          entity_class       = ""
          entity_type        = ""
          entity_description = ""
          entity_details     = []
          hardware_family    = ""
          hardware_vendor    = ""
          target_version     = ""
          last_updated_time  = ""
          group_uuid         = ""
          links              = []
          location_info      = []
          sub_entities       = []
          child_entities     = []

          available_versions = [
            {
              version                = "5.4.0"
              order                  = 20
              status                 = "AVAILABLE"
              is_enabled             = false
              available_version_uuid = ""
              disablement_reason     = ""
              release_notes          = ""
              release_date           = ""
              custom_message         = ""
              child_entities         = []
              group_uuid             = ""
              dependencies           = []
            },
            {
              version                = "5.3.1.1"
              order                  = 12
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
            },
          ]
        },
      ]
    }
  }

  assert {
    condition     = output.lcm_latest_version_by_entity["9bc0e3ec-d3f5-4244-967c-bac006498b08"] == "5.3.0.3"
    error_message = "FSM 'latest' must resolve to the highest-ordered version 5.3.0.3, got ${output.lcm_latest_version_by_entity["9bc0e3ec-d3f5-4244-967c-bac006498b08"]}"
  }

  assert {
    condition     = output.lcm_latest_version_by_entity["8b1920c1-de2c-4b73-abc8-7f7ec086dba6"] == "5.3.1.1"
    error_message = "NCC 'latest' must skip the disabled 5.4.0 and resolve to 5.3.1.1, got ${output.lcm_latest_version_by_entity["8b1920c1-de2c-4b73-abc8-7f7ec086dba6"]}"
  }
}
