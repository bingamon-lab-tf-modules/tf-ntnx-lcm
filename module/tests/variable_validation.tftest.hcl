# OpenTofu/Terraform Test File for tf-ntnx-lcm Module
# Tests focus on variable validation with complete provider mocking

# Mock the provider to prevent real API calls
mock_provider "nutanix" {
  # Mock Prism Central cluster lookup
  mock_data "nutanix_clusters_v2" {
    defaults = {
      # Provide complete cluster_entities structure as required by schema
      cluster_entities = [{
        ext_id                      = "00000000-0000-0000-0000-000000000000"
        name                        = "mock-prism-central"
        backup_eligibility_score    = 100
        categories                  = []
        cluster_profile_ext_id      = "mock-profile-id"
        container_name              = "mock-container"
        expand                      = ""
        inefficient_vm_count        = 0
        links                       = []
        network                     = {}
        nodes                       = []
        tenant_id                   = "mock-tenant"
        upgrade_status              = "NONE"
        vm_count                    = 0
        config = [{
          hypervisor_types = ["AHV"]
          cluster_function = ["PRISM_CENTRAL"]
        }]
      }]
    }
  }

  # Mock LCM entities lookup
  mock_data "nutanix_lcm_entities_v2" {
    defaults = {
      entities = []
    }
  }

  # Mock individual LCM entity lookup
  mock_data "nutanix_lcm_entity_v2" {
    defaults = {
      ext_id         = "mock-entity-id"
      entity_model   = "AOS"
      entity_version = "7.0.1.6"
    }
  }

  # Mock LCM status check
  mock_data "nutanix_lcm_status_v2" {
    defaults = {
      in_progress_operation = [{
        operation_type = ""
        operation_id   = ""
      }]
    }
  }

  # Mock local file data source (used for cluster validation)
  mock_data "local_file" {
    defaults = {
      content  = ""
      filename = "/dev/null"
    }
  }

  # Mock resources that might be created
  mock_resource "nutanix_lcm_config_v2" {
    defaults = {
      x_cluster_id = "mock-cluster-id"
    }
  }

  mock_resource "nutanix_lcm_perform_inventory_v2" {
    defaults = {
      x_cluster_id = "mock-cluster-id"
    }
  }

  mock_resource "nutanix_lcm_prechecks_v2" {
    defaults = {
      x_cluster_id = "mock-cluster-id"
      ext_id       = "mock-precheck-id"
    }
  }

  mock_resource "nutanix_lcm_upgrade_v2" {
    defaults = {
      x_cluster_id = "mock-cluster-id"
    }
  }
}

# Test 1: Validate DarkSite requires URL for clusters
run "cluster_darksite_requires_url" {
  command = plan

  variables {
    clusters = {
      "test_cluster" = {
        name              = "test-cluster"
        connectivity_type = "DARKSITE_WEB_SERVER"
        darksite_url      = null  # Invalid: should fail validation
      }
    }
    prism_central = {}
  }

  expect_failures = [var.prism_element]
}

# Test 2: Validate inventory required for prechecks
run "cluster_prechecks_requires_inventory" {
  command = plan

  variables {
    clusters = {
      "test_cluster" = {
        name              = "test-cluster"
        perform_inventory = false
        perform_prechecks = true  # Invalid: requires inventory
      }
    }
    prism_central = {}
  }

  expect_failures = [var.prism_element]
}

# Test 3: Validate inventory required for upgrade
run "cluster_upgrade_requires_inventory" {
  command = plan

  variables {
    clusters = {
      "test_cluster" = {
        name              = "test-cluster"
        perform_inventory = false
        perform_upgrade   = true  # Invalid: requires inventory
      }
    }
    prism_central = {}
  }

  expect_failures = [var.prism_element]
}

# Test 4: Validate connectivity type values
run "cluster_invalid_connectivity_type" {
  command = plan

  variables {
    clusters = {
      "test_cluster" = {
        name              = "test-cluster"
        connectivity_type = "INVALID"  # Invalid: must be INTERNET or DARKSITE_WEB_SERVER
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
    clusters = {
      "test_cluster" = {
        name = "test-cluster"
        management_server = {
          hypervisor_type = "ESXi"
          ip              = "192.168.1.1"
          username        = "admin"
          password        = null  # Invalid: all fields required
        }
      }
    }
    prism_central = {}
  }

  expect_failures = [var.prism_element]
}

# Test 6: Validate at least one entity required for upgrade
run "cluster_upgrade_needs_entities" {
  command = plan

  variables {
    clusters = {
      "test_cluster" = {
        name                = "test-cluster"
        perform_inventory   = true
        perform_upgrade     = true
        entities_to_upgrade = {}  # Invalid: needs at least one entity
      }
    }
    prism_central = {}
  }

  expect_failures = [var.prism_element]
}

# Test 7: Prism Central DarkSite requires URL
run "prism_central_darksite_requires_url" {
  command = plan

  variables {
    clusters = {}
    prism_central = {
      connectivity_type = "DARKSITE_WEB_SERVER"
      darksite_url      = null  # Invalid: should fail validation
    }
  }

  expect_failures = [var.prism_central]
}

# Test 8: Prism Central prechecks requires inventory
run "prism_central_prechecks_requires_inventory" {
  command = plan

  variables {
    clusters = {}
    prism_central = {
      perform_inventory = false
      perform_prechecks = true  # Invalid: requires inventory
    }
  }

  expect_failures = [var.prism_central]
}

# Test 9: Prism Central upgrade requires inventory
run "prism_central_upgrade_requires_inventory" {
  command = plan

  variables {
    clusters = {}
    prism_central = {
      perform_inventory = false
      perform_upgrade   = true  # Invalid: requires inventory
    }
  }

  expect_failures = [var.prism_central]
}

# Test 10: Prism Central upgrade needs entities
run "prism_central_upgrade_needs_entities" {
  command = plan

  variables {
    clusters = {}
    prism_central = {
      perform_inventory   = true
      perform_upgrade     = true
      entities_to_upgrade = {}  # Invalid: needs at least one entity
    }
  }

  expect_failures = [var.prism_central]
}

# Test 11: Valid minimal configuration
run "valid_minimal_config" {
  command = plan

  variables {
    clusters      = {}
    prism_central = {}
  }

  # Check basic outputs work
  assert {
    condition     = output.summary.total_clusters == 0
    error_message = "Expected 0 clusters"
  }

  assert {
    condition     = output.summary.inventory_clusters == 0
    error_message = "Expected 0 inventory clusters"
  }
}

# Test 12: Valid DarkSite cluster configuration
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
    error_message = "Expected 1 cluster"
  }

  assert {
    condition     = contains(output.summary.darksite_clusters, "darksite-cluster")
    error_message = "Expected darksite-cluster in darksite_clusters list"
  }
}

# Test 13: Valid upgrade configuration
run "valid_upgrade_config" {
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
    condition     = output.summary.upgrade_clusters == 1
    error_message = "Expected 1 upgrade cluster"
  }

  assert {
    condition     = output.cluster_entities_to_upgrade["upgrade_cluster"]["AOS"].target_version == "7.0.1.7"
    error_message = "Expected AOS target version to be 7.0.1.7"
  }
}

# Test 14: Valid Prism Central configuration
run "valid_prism_central_config" {
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

  assert {
    condition     = output.prism_central_entities_to_upgrade["PC"].entity_model == "PC"
    error_message = "Expected PC entity model"
  }

  assert {
    condition     = output.prism_central_entities_to_upgrade["PC"].target_version == "pc.2024.3.1.8"
    error_message = "Expected specific PC version"
  }
}

# Test 15: Multiple clusters with different configurations
run "multiple_clusters" {
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
    }
    prism_central = {
      connectivity_type = "INTERNET"
    }
  }

  assert {
    condition     = output.summary.total_clusters == 2
    error_message = "Expected 2 clusters"
  }

  assert {
    condition     = output.summary.inventory_clusters == 1
    error_message = "Expected 1 inventory cluster"
  }

  assert {
    condition     = length(output.summary.darksite_clusters) == 1
    error_message = "Expected 1 darksite cluster"
  }
}
