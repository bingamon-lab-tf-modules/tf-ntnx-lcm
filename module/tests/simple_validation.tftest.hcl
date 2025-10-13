# Simple validation tests for tf-ntnx-lcm module
# These tests verify variable validations work without requiring real Nutanix infrastructure

# Configure provider with dummy values to prevent connection attempts
provider "nutanix" {
  username     = "dummy"
  password     = "dummy"
  endpoint     = "dummy.local"
  port         = 9440
  insecure     = true
  wait_timeout = 1
}

# Mock all provider interactions
mock_provider "nutanix" {
  # Mock the Prism Central lookup with minimal required fields
  mock_data "nutanix_clusters_v2" {
    defaults = {
      cluster_entities = [
        {
          ext_id                   = "00000000-0000-0000-0000-000000000000"
          name                     = "mock-pc"
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

  # Mock LCM entities with empty response
  mock_data "nutanix_lcm_entities_v2" {
    defaults = {
      entities = []
    }
  }

  # Mock LCM entity lookup
  mock_data "nutanix_lcm_entity_v2" {
    defaults = {
      ext_id         = "mock-id"
      entity_model   = "mock"
      entity_version = "0.0.0"
    }
  }

  # Mock LCM status
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

mock_provider "local" {
  mock_data "local_file" {
    defaults = {
      content = ""
    }
  }
}

# Test 1: Empty configuration should work
run "empty_config" {
  command = plan

  variables {
    prism_element = {}
    prism_central = {}
  }

  assert {
    condition     = output.summary.total_clusters == 0
    error_message = "Expected 0 clusters"
  }
}

# Test 2: DarkSite without URL should fail
run "darksite_without_url" {
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
run "prechecks_without_inventory" {
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
run "upgrade_without_inventory" {
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
run "invalid_connectivity_type" {
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
run "valid_darksite" {
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
    condition     = output.summary.total_clusters == 1
    error_message = "Expected 1 cluster"
  }
}

# Test 7: Valid upgrade configuration
run "valid_upgrade" {
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
    condition     = output.summary.upgrade_clusters == 1
    error_message = "Expected 1 upgrade cluster"
  }
}

# Test 8: Prism Central DarkSite without URL should fail
run "pc_darksite_without_url" {
  command = plan

  variables {
    prism_element = {}
    prism_central = {
      connectivity_type = "DARKSITE_WEB_SERVER"
      darksite_url      = null
    }
  }

  expect_failures = [var.prism_central]
}

# Test 9: Prism Central prechecks without inventory should fail
run "pc_prechecks_without_inventory" {
  command = plan

  variables {
    prism_element = {}
    prism_central = {
      perform_inventory = false
      perform_prechecks = true
    }
  }

  expect_failures = [var.prism_central]
}

# Test 10: Valid Prism Central configuration
run "valid_prism_central" {
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
