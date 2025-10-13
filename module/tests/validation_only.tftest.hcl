# Variable Validation Tests for tf-ntnx-lcm Module
# These tests validate input variable constraints without requiring a real Nutanix cluster

# Mock provider to prevent real API calls
mock_provider "nutanix" {
  # Mock Prism Central data source with all required fields
  mock_data "nutanix_clusters_v2" {
    defaults = {
      cluster_entities = [
        {
          ext_id                   = "00000000-0000-0000-0000-000000000000"
          name                     = "mock-prism-central"
          backup_eligibility_score = 0
          categories               = []
          cluster_profile_ext_id   = ""
          container_name           = ""
          expand                   = ""
          inefficient_vm_count     = 0
          links                    = []
          network                  = {}
          nodes                    = []
          tenant_id                = ""
          upgrade_status           = ""
          vm_count                 = 0
          config = [
            {
              hypervisor_types = ["AHV"]
            }
          ]
        }
      ]
    }
  }

  # Mock LCM entities data source
  mock_data "nutanix_lcm_entities_v2" {
    defaults = {
      entities = []
    }
  }

  # Mock LCM entity data source
  mock_data "nutanix_lcm_entity_v2" {
    defaults = {
      ext_id         = "mock-entity-id"
      entity_model   = "AOS"
      entity_version = "7.0.1.6"
    }
  }

  # Mock LCM status data source
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

# Mock the local provider to avoid file system checks
mock_provider "local" {
  mock_data "local_file" {
    defaults = {
      content  = ""
      filename = "/dev/null"
    }
  }
}

# ============================================================================
# CLUSTER VARIABLE VALIDATION TESTS
# ============================================================================

# Test: DarkSite cluster requires URL
run "cluster_darksite_requires_url" {
  command = plan

  variables {
    clusters = {
      "darksite_cluster" = {
        name              = "darksite-cluster"
        connectivity_type = "DARKSITE_WEB_SERVER"
        darksite_url      = null  # This should fail validation
      }
    }
    prism_central = {}
  }

  expect_failures = [
    var.prism_element,  # Expect variable validation to fail
  ]
}

# Test: Invalid connectivity type for cluster
run "cluster_invalid_connectivity_type" {
  command = plan

  variables {
    clusters = {
      "test_cluster" = {
        name              = "test-cluster"
        connectivity_type = "INVALID_TYPE"  # Should only be INTERNET or DARKSITE_WEB_SERVER
      }
    }
    prism_central = {}
  }

  expect_failures = [
    var.prism_element,
  ]
}

# Test: Cluster prechecks requires inventory
run "cluster_prechecks_requires_inventory" {
  command = plan

  variables {
    clusters = {
      "test_cluster" = {
        name              = "test-cluster"
        perform_inventory = false
        perform_prechecks = true  # This should fail - prechecks requires inventory
      }
    }
    prism_central = {}
  }

  expect_failures = [
    var.prism_element,
  ]
}

# Test: Cluster upgrade requires inventory
run "cluster_upgrade_requires_inventory" {
  command = plan

  variables {
    clusters = {
      "test_cluster" = {
        name              = "test-cluster"
        perform_inventory = false
        perform_upgrade   = true  # This should fail - upgrade requires inventory
      }
    }
    prism_central = {}
  }

  expect_failures = [
    var.prism_element,
  ]
}

# Test: Cluster upgrade requires at least one entity
run "cluster_upgrade_requires_entities" {
  command = plan

  variables {
    clusters = {
      "test_cluster" = {
        name                = "test-cluster"
        perform_inventory   = true
        perform_upgrade     = true
        entities_to_upgrade = {}  # This should fail - need at least one entity
      }
    }
    prism_central = {}
  }

  expect_failures = [
    var.prism_element,
  ]
}

# Test: Incomplete management server configuration
run "cluster_incomplete_management_server" {
  command = plan

  variables {
    clusters = {
      "test_cluster" = {
        name = "test-cluster"
        management_server = {
          hypervisor_type = "ESXi"
          ip              = "192.168.1.1"
          username        = null  # This should fail - all fields required
          password        = "password"
        }
      }
    }
    prism_central = {}
  }

  expect_failures = [
    var.prism_element,
  ]
}

# ============================================================================
# PRISM CENTRAL VARIABLE VALIDATION TESTS
# ============================================================================

# Test: Prism Central DarkSite requires URL
run "prism_central_darksite_requires_url" {
  command = plan

  variables {
    clusters = {}
    prism_central = {
      connectivity_type = "DARKSITE_WEB_SERVER"
      darksite_url      = null  # This should fail validation
    }
  }

  expect_failures = [
    var.prism_central,
  ]
}

# Test: Invalid connectivity type for Prism Central
run "prism_central_invalid_connectivity_type" {
  command = plan

  variables {
    clusters = {}
    prism_central = {
      connectivity_type = "INVALID_TYPE"  # Should only be INTERNET or DARKSITE_WEB_SERVER
    }
  }

  expect_failures = [
    var.prism_central,
  ]
}

# Test: Prism Central prechecks requires inventory
run "prism_central_prechecks_requires_inventory" {
  command = plan

  variables {
    clusters = {}
    prism_central = {
      perform_inventory = false
      perform_prechecks = true  # This should fail - prechecks requires inventory
    }
  }

  expect_failures = [
    var.prism_central,
  ]
}

# Test: Prism Central upgrade requires inventory
run "prism_central_upgrade_requires_inventory" {
  command = plan

  variables {
    clusters = {}
    prism_central = {
      perform_inventory = false
      perform_upgrade   = true  # This should fail - upgrade requires inventory
    }
  }

  expect_failures = [
    var.prism_central,
  ]
}

# Test: Prism Central upgrade requires at least one entity
run "prism_central_upgrade_requires_entities" {
  command = plan

  variables {
    clusters = {}
    prism_central = {
      perform_inventory   = true
      perform_upgrade     = true
      entities_to_upgrade = {}  # This should fail - need at least one entity
    }
  }

  expect_failures = [
    var.prism_central,
  ]
}

# ============================================================================
# VALID CONFIGURATION TESTS
# ============================================================================

# Test: Empty configuration is valid
run "empty_configuration_valid" {
  command = plan

  variables {
    clusters      = {}
    prism_central = {}
  }

  assert {
    condition     = output.summary.total_clusters == 0
    error_message = "Expected 0 total clusters"
  }

  assert {
    condition     = output.summary.inventory_clusters == 0
    error_message = "Expected 0 inventory clusters"
  }

  assert {
    condition     = output.summary.precheck_clusters == 0
    error_message = "Expected 0 precheck clusters"
  }

  assert {
    condition     = output.summary.upgrade_clusters == 0
    error_message = "Expected 0 upgrade clusters"
  }
}

# Test: Valid DarkSite cluster configuration
run "valid_darksite_cluster" {
  command = plan

  variables {
    clusters = {
      "darksite_cluster" = {
        name              = "darksite-cluster"
        connectivity_type = "DARKSITE_WEB_SERVER"
        darksite_url      = "https://darksite.example.com/lcm"
        perform_inventory = false
      }
    }
    prism_central = {}
  }

  assert {
    condition     = output.summary.total_clusters == 1
    error_message = "Expected 1 total cluster"
  }

  assert {
    condition     = contains(output.summary.darksite_clusters, "darksite-cluster")
    error_message = "Expected darksite-cluster in darksite_clusters list"
  }
}

# Test: Valid cluster upgrade configuration
run "valid_cluster_upgrade" {
  command = plan

  variables {
    clusters = {
      "upgrade_cluster" = {
        name              = "upgrade-cluster"
        perform_inventory = true
        perform_prechecks = true
        perform_upgrade   = true
        entities_to_upgrade = {
          "AOS" = {
            entity_model   = "AOS"
            target_version = "7.0.1.7"
          }
        }
      }
    }
    prism_central = {}
  }

  assert {
    condition     = output.summary.total_clusters == 1
    error_message = "Expected 1 total cluster"
  }

  assert {
    condition     = output.summary.upgrade_clusters == 1
    error_message = "Expected 1 upgrade cluster"
  }

  assert {
    condition     = output.cluster_entities_to_upgrade["upgrade_cluster"]["AOS"].target_version == "7.0.1.7"
    error_message = "Expected AOS target version 7.0.1.7"
  }
}

# Test: Valid Prism Central configuration
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
        "NCC" = {
          entity_model   = "NCC"
          target_version = "latest"
        }
      }
    }
  }

  assert {
    condition     = output.prism_central_entities_to_upgrade["PC"].target_version == "pc.2024.3.1.8"
    error_message = "Expected PC target version pc.2024.3.1.8"
  }

  assert {
    condition     = output.prism_central_entities_to_upgrade["NCC"].target_version == "latest"
    error_message = "Expected NCC target version latest"
  }
}

# Test: Valid management server configuration
run "valid_management_server" {
  command = plan

  variables {
    clusters = {
      "esxi_cluster" = {
        name = "esxi-cluster"
        management_server = {
          hypervisor_type = "ESXi"
          ip              = "192.168.1.100"
          username        = "administrator@vsphere.local"
          password        = "SecurePassword123!"
        }
      }
    }
    prism_central = {}
  }

  assert {
    condition     = output.summary.total_clusters == 1
    error_message = "Expected 1 total cluster"
  }
}

# Test: Multiple valid clusters
run "multiple_clusters_valid" {
  command = plan

  variables {
    clusters = {
      "internet_cluster" = {
        name              = "internet-cluster"
        connectivity_type = "INTERNET"
        perform_inventory = true
      }
      "darksite_cluster" = {
        name              = "darksite-cluster"
        connectivity_type = "DARKSITE_WEB_SERVER"
        darksite_url      = "https://darksite.example.com"
        perform_inventory = false
      }
      "upgrade_cluster" = {
        name              = "upgrade-cluster"
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
    condition     = output.summary.total_clusters == 3
    error_message = "Expected 3 total clusters"
  }

  assert {
    condition     = output.summary.inventory_clusters == 2
    error_message = "Expected 2 inventory clusters"
  }

  assert {
    condition     = output.summary.upgrade_clusters == 1
    error_message = "Expected 1 upgrade cluster"
  }

  assert {
    condition     = length(output.summary.darksite_clusters) == 1
    error_message = "Expected 1 darksite cluster"
  }
}
