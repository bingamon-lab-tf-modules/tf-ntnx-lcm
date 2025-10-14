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
      ext_id         = "mock-id"
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
      connectivity_type = "DARKSITE_WEB_SERVER"
      darksite_url      = null
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
      perform_inventory = false
      perform_prechecks = true
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
      perform_inventory = false
      perform_upgrade   = true
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
      connectivity_type = "INVALID"
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
      connectivity_type = "DARKSITE_WEB_SERVER"
      darksite_url      = "https://darksite.local"
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
