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

  # Prism Element entity lookup
  mock_data "nutanix_lcm_entity_v2" {
    defaults = {
      ext_id         = "mock-id"
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
