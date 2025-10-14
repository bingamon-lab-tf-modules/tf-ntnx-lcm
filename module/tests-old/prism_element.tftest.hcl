# OpenTofu/Terraform Test File for tf-ntnx-lcm Module
# These tests focus on variable validation without requiring data source execution

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
          network                  = [] # Fixed: list of object (empty list satisfies type)
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

# Test 1: Validate DarkSite requires URL for clusters
run "cluster_darksite_requires_url" {
  command = plan

  variables {
    prism_element = {
      "test_cluster" = {
        name              = "test-cluster"
        connectivity_type = "DARKSITE_WEB_SERVER"
        darksite_url      = null # Invalid: DarkSite requires URL
      }
    }
    prism_central = {}
  }

  expect_failures = [var.prism_element]
}

# Test 2: Validate inventory requirement for cluster prechecks
run "cluster_prechecks_requires_inventory" {
  command = plan

  variables {
    prism_element = {
      "test_cluster" = {
        name              = "test-cluster"
        perform_inventory = false
        perform_prechecks = true
      }
    }
    prism_central = {}
  }

  expect_failures = [var.prism_element]
}

# Test 3: Validate inventory requirement for cluster upgrade
run "cluster_upgrade_requires_inventory" {
  command = plan

  variables {
    prism_element = {
      "test_cluster" = {
        name              = "test-cluster"
        perform_inventory = false
        perform_upgrade   = true
      }
    }
    prism_central = {}
  }

  expect_failures = [var.prism_element]
}

# Test 4: Validate invalid connectivity type for clusters
run "cluster_invalid_connectivity_type" {
  command = plan

  variables {
    prism_element = {
      "test_cluster" = {
        name              = "test-cluster"
        connectivity_type = "INVALID_TYPE" # Invalid: must be INTERNET or DARKSITE_WEB_SERVER
      }
    }
    prism_central = {}
  }

  expect_failures = [var.prism_element]
}

# Test 5: Validate management server requires all fields
run "cluster_management_server_incomplete" {
  command = plan

  variables {
    prism_element = {
      "test_cluster" = {
        name = "test-cluster"
        management_server = {
          hypervisor_type = "ESXi"
          ip              = "192.168.1.1"
          username        = "admin"
          password        = null # Invalid: all fields required
        }
      }
    }
    prism_central = {}
  }

  expect_failures = [var.prism_element]
}

# Test 6: Validate DarkSite requires URL for Prism Central
run "prism_central_darksite_requires_url" {
  command = plan

  variables {
    prism_element = {}
    prism_central = {
      connectivity_type = "DARKSITE_WEB_SERVER"
      darksite_url      = null # Invalid: DarkSite requires URL
    }
  }

  expect_failures = [var.prism_central]
}

# Test 7: Validate inventory requirement for Prism Central prechecks
run "prism_central_prechecks_requires_inventory" {
  command = plan

  variables {
    prism_element = {}
    prism_central = {
      perform_inventory = false
      perform_prechecks = true # Invalid: prechecks requires inventory
    }
  }

  expect_failures = [var.prism_central]
}

# Test 8: Validate inventory requirement for Prism Central upgrade
run "prism_central_upgrade_requires_inventory" {
  command = plan

  variables {
    clusters = {}
    prism_central = {
      perform_inventory = false # Invalid: upgrade requires inventory
      perform_upgrade   = true
    }
  }

  expect_failures = [var.prism_central]
}

# Test 9: Validate invalid connectivity type for Prism Central
run "prism_central_invalid_connectivity_type" {
  command = plan

  variables {
    prism_element = {}
    prism_central = {
      connectivity_type = "INVALID_TYPE" # Invalid: must be INTERNET or DARKSITE_WEB_SERVER
    }
  }

  expect_failures = [var.prism_central]
}

# Test 10: Valid minimal configuration (should not fail)
# Note: This will still fail at plan stage due to missing provider config/data sources,
# but it validates that variable validations pass
run "valid_minimal_config" {
  command = plan

  variables {
    prism_element = {
      "test_cluster" = {
        name              = "test-cluster"
        connectivity_type = "INTERNET"
        perform_inventory = false # Not performing any actions
      }
    }
    prism_central = {
      connectivity_type = "INTERNET"
    }
  }

  # This test validates that variable validation passes with mocking
}

# Test 11: Valid DarkSite cluster configuration
run "valid_darksite_cluster_config" {
  command = plan

  variables {
    prism_element = {
      "test_cluster" = {
        name              = "test-cluster"
        connectivity_type = "DARKSITE_WEB_SERVER"
        darksite_url      = "https://darksite.example.com/lcm"
        perform_inventory = false
      }
    }
    prism_central = {}
  }


}

# Test 12: Valid Prism Central upgrade configuration
run "valid_prism_central_upgrade" {
  command = plan

  variables {
    clusters = {}
    prism_central = {
      perform_inventory = true
      perform_prechecks = true
      perform_upgrade   = true
      entities_to_upgrade = {
        "PC" = {
          entity_model   = "PC"
          target_version = "pc.2024.3.1.8"
        }
      }
    }
  }


}

# Test 13: Valid cluster with specific version targets
run "valid_cluster_specific_versions" {
  command = plan

  variables {
    prism_element = {
      "prod_cluster" = {
        name              = "prod-cluster"
        perform_inventory = true
        perform_prechecks = true
        perform_upgrade   = true
        entities_to_upgrade = {
          "AOS" = {
            entity_model   = "AOS"
            target_version = "7.0.1.7"
          }
          "AHV hypervisor" = {
            entity_model   = "AHV hypervisor"
            target_version = "10.0.1.2"
          }
        }
      }
    }
    prism_central = {}
  }


}
