# tf-ntnx-lcm

## Table of Contents

## Overview

A Terraform module for managing Nutanix Lifecycle Management (LCM) configurations.

This module can manage two types of LCM configurations:

1. Prism Central
2. Prism Element

Depending on which type will determine the required variables.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.0 |
| <a name="requirement_nutanix"></a> [nutanix](#requirement\_nutanix) | 2.3.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_local"></a> [local](#provider\_local) | 2.5.3 |
| <a name="provider_nutanix"></a> [nutanix](#provider\_nutanix) | 2.3.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [nutanix_lcm_config_v2.cluster_lcm_settings](https://registry.terraform.io/providers/nutanix/nutanix/2.3.1/docs/resources/lcm_config_v2) | resource |
| [nutanix_lcm_config_v2.prism_central_lcm_settings](https://registry.terraform.io/providers/nutanix/nutanix/2.3.1/docs/resources/lcm_config_v2) | resource |
| [nutanix_lcm_perform_inventory_v2.cluster_inventory](https://registry.terraform.io/providers/nutanix/nutanix/2.3.1/docs/resources/lcm_perform_inventory_v2) | resource |
| [nutanix_lcm_perform_inventory_v2.prism_central_inventory](https://registry.terraform.io/providers/nutanix/nutanix/2.3.1/docs/resources/lcm_perform_inventory_v2) | resource |
| [nutanix_lcm_prechecks_v2.cluster_prechecks](https://registry.terraform.io/providers/nutanix/nutanix/2.3.1/docs/resources/lcm_prechecks_v2) | resource |
| [nutanix_lcm_prechecks_v2.prism_central_prechecks](https://registry.terraform.io/providers/nutanix/nutanix/2.3.1/docs/resources/lcm_prechecks_v2) | resource |
| [nutanix_lcm_upgrade_v2.cluster_upgrade](https://registry.terraform.io/providers/nutanix/nutanix/2.3.1/docs/resources/lcm_upgrade_v2) | resource |
| [nutanix_lcm_upgrade_v2.prism_central_upgrade](https://registry.terraform.io/providers/nutanix/nutanix/2.3.1/docs/resources/lcm_upgrade_v2) | resource |
| [local_file.missing_cluster_check](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) | data source |
| [nutanix_clusters_v2.prism_central_cluster](https://registry.terraform.io/providers/nutanix/nutanix/2.3.1/docs/data-sources/clusters_v2) | data source |
| [nutanix_clusters_v2.prism_element_cluster](https://registry.terraform.io/providers/nutanix/nutanix/2.3.1/docs/data-sources/clusters_v2) | data source |
| [nutanix_lcm_entities_v2.prism_central_lcm_entities](https://registry.terraform.io/providers/nutanix/nutanix/2.3.1/docs/data-sources/lcm_entities_v2) | data source |
| [nutanix_lcm_entities_v2.prism_element_lcm_entities](https://registry.terraform.io/providers/nutanix/nutanix/2.3.1/docs/data-sources/lcm_entities_v2) | data source |
| [nutanix_lcm_entity_v2.prism_central_lcm_entities_after_upgrade](https://registry.terraform.io/providers/nutanix/nutanix/2.3.1/docs/data-sources/lcm_entity_v2) | data source |
| [nutanix_lcm_entity_v2.prism_central_lcm_entities_before_upgrade](https://registry.terraform.io/providers/nutanix/nutanix/2.3.1/docs/data-sources/lcm_entity_v2) | data source |
| [nutanix_lcm_entity_v2.prism_element_lcm_entities_before_upgrade](https://registry.terraform.io/providers/nutanix/nutanix/2.3.1/docs/data-sources/lcm_entity_v2) | data source |
| [nutanix_lcm_status_v2.prism_central_lcm_status_after_upgrade](https://registry.terraform.io/providers/nutanix/nutanix/2.3.1/docs/data-sources/lcm_status_v2) | data source |
| [nutanix_lcm_status_v2.prism_central_lcm_status_before_prechecks](https://registry.terraform.io/providers/nutanix/nutanix/2.3.1/docs/data-sources/lcm_status_v2) | data source |
| [nutanix_lcm_status_v2.prism_central_lcm_status_before_upgrade](https://registry.terraform.io/providers/nutanix/nutanix/2.3.1/docs/data-sources/lcm_status_v2) | data source |
| [nutanix_lcm_status_v2.prism_element_lcm_status_after_upgrade](https://registry.terraform.io/providers/nutanix/nutanix/2.3.1/docs/data-sources/lcm_status_v2) | data source |
| [nutanix_lcm_status_v2.prism_element_lcm_status_before_prechecks](https://registry.terraform.io/providers/nutanix/nutanix/2.3.1/docs/data-sources/lcm_status_v2) | data source |
| [nutanix_lcm_status_v2.prism_element_lcm_status_before_upgrade](https://registry.terraform.io/providers/nutanix/nutanix/2.3.1/docs/data-sources/lcm_status_v2) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_prism_central"></a> [prism\_central](#input\_prism\_central) | Prism Central configuration for LCM actions. | <pre>object({<br/>    # General & Actions<br/>    perform_inventory = optional(bool, false) # Whether to perform an inventory scan.<br/>    perform_prechecks = optional(bool, false) # Whether to perform upgrade pre-checks.<br/>    perform_upgrade   = optional(bool, false) # Whether to perform the upgrade.<br/><br/>    # LCM Configuration for Prism Central<br/>    connectivity_type               = optional(string, "INTERNET")<br/>    darksite_url                    = optional(string, null)<br/>    is_auto_inventory_enabled       = optional(bool, true)<br/>    auto_inventory_schedule         = optional(string, "00:00")<br/>    is_https_enabled                = optional(bool, true)<br/>    has_module_auto_upgrade_enabled = optional(bool, false)<br/><br/>    # The entities to upgrade<br/>    entities_to_upgrade = optional(map(object({<br/>      entity_model   = string<br/>      target_version = optional(string, "latest")<br/>      })), {<br/>      "AOS" = {<br/>        entity_model   = "AOS"<br/>        target_version = "latest" # Example current: "7.0.1.6", target_version: "7.0.1.7"<br/>      },<br/>      "Epsilon" = {<br/>        entity_model   = "Epsilon"<br/>        target_version = "latest" # Example current: "4.1.1", target_version: "4.1.2"<br/>      },<br/>      "Files Manager" = {<br/>        entity_model   = "Files Manager"<br/>        target_version = "latest" # Example current: "5.2", target_version: "5.3"<br/>      },<br/>      "Licensing" = {<br/>        entity_model   = "Licensing"<br/>        target_version = "latest" # Example current: "LM.2024.2.9" or "LM.2025.2", target_version: "LM.2025.2"<br/>      },<br/>      "MSP" = {<br/>        entity_model   = "MSP"<br/>        target_version = "latest" # Example current: "2.6.1.5", target_version: "2.6.1.5"<br/>      },<br/>      "NCC" = {<br/>        entity_model   = "NCC"<br/>        target_version = "latest" # Example current: "5.2.0.1" or "5.2.0", target_version: "5.2.0.1"<br/>      },<br/>      "Network Controller" = {<br/>        entity_model   = "Network Controller"<br/>        target_version = "latest" # Example current: "5.0.0", target_version: "5.0.1"<br/>      },<br/>      "Objects Manager" = {<br/>        entity_model   = "Objects Manager"<br/>        target_version = "latest" # Example current: "5.1.1.1", target_version: "5.1.1.2"<br/>      },<br/>      "PC" = {<br/>        entity_model   = "PC"<br/>        target_version = "latest" # Example current: "pc.2024.3.1.7", target_version: "pc.2024.3.1.8"<br/>      }<br/>      "PC Core Services" = {<br/>        entity_model   = "PC Core Services"<br/>        target_version = "latest" # Example current: "4.3.36", target_version: "4.3.37"<br/>      },<br/>      "Security Dashboard CVE Data" = {<br/>        entity_model   = "Security Dashboard CVE Data"<br/>        target_version = "latest" # Example current: "2025.08.1", target_version: "2025.08.2"<br/>      },<br/>      "Self Service" = {<br/>        entity_model   = "Self Service"<br/>        target_version = "latest" # Example current: "4.1.1", target_version: "4.1.2"<br/>      }<br/>    })<br/><br/>    # Pre-check & Upgrade flags<br/>    skipped_precheck_flags = optional(list(string), [])<br/>    auto_handle_flags      = optional(list(string), [])<br/>    max_wait_time_in_secs  = optional(number, 3600)<br/><br/>    # Management Server for hypervisor upgrades (e.g., ESXi)<br/>    management_server = optional(object({<br/>      hypervisor_type = string<br/>      ip              = string<br/>      username        = string<br/>      password        = string<br/>    }), null)<br/>  })</pre> | `{}` | no |
| <a name="input_prism_element"></a> [prism\_element](#input\_prism\_element) | A optional map of Nutanix cluster configurations for LCM actions. | <pre>map(object({<br/>    # General & Actions<br/>    name              = string<br/>    perform_inventory = optional(bool, false) # Whether to perform an inventory scan.<br/>    perform_prechecks = optional(bool, false) # Whether to perform pre-checks.<br/>    perform_upgrade   = optional(bool, false) # Whether to perform an upgrade.<br/><br/>    # LCM Configuration (per-cluster)<br/>    connectivity_type               = optional(string, "INTERNET")<br/>    darksite_url                    = optional(string, null)<br/>    is_auto_inventory_enabled       = optional(bool, true)<br/>    auto_inventory_schedule         = optional(string, "00:00")<br/>    is_https_enabled                = optional(bool, true)<br/>    has_module_auto_upgrade_enabled = optional(bool, false)<br/><br/>    # The entities to upgrade<br/>    entities_to_upgrade = optional(map(object({<br/>      entity_model   = string<br/>      target_version = optional(string, "latest")<br/>      })), {<br/>      "AHV hypervisor" = {<br/>        entity_model   = "AHV hypervisor"<br/>        target_version = "latest" # Example current: "10.0.1.1", target_version: "10.0.1.2"<br/>      },<br/>      "AOS" = {<br/>        entity_model   = "AOS"<br/>        target_version = "latest" # Example current: "7.0.1.6", target_version: "7.0.1.7"<br/>      },<br/>      "FSM" = {<br/>        entity_model   = "FSM"<br/>        target_version = "latest" # Example current: "5.2" or "5.0.0.3", target_version: "5.2"<br/>      },<br/>      "Foundation" = {<br/>        entity_model   = "Foundation"<br/>        target_version = "latest" # Example current: "5.9.1", target_version: "5.9.2"<br/>      },<br/>      "Foundation Platforms" = {<br/>        entity_model   = "Foundation Platforms"<br/>        target_version = "latest" # Example current: "2.18.1", target_version: "2.18.2"<br/>      },<br/>      "Licensing" = {<br/>        entity_model   = "Licensing"<br/>        target_version = "latest" # Example current: "LM.2024.2.9" or "LM.2025.2", target_version: "LM.2024.2"<br/>      },<br/>      "NCC" = {<br/>        entity_model   = "NCC"<br/>        target_version = "latest" # Example current: "5.2.0.1" or "5.2.0", target_version: "5.2.0.1"<br/>      },<br/>      "Security AOS" = {<br/>        entity_model   = "Security AOS"<br/>        target_version = "latest" # Example current: "security_aos.2022.9", target_version: "security_aos.2023.1"<br/>      }<br/>    })<br/><br/>    # Pre-check & Upgrade flags<br/>    skipped_precheck_flags = optional(list(string), [])<br/>    auto_handle_flags      = optional(list(string), [])<br/>    max_wait_time_in_secs  = optional(number, 3600)<br/><br/>    # Management Server for hypervisor upgrades (e.g., ESXi)<br/>    management_server = optional(object({<br/>      hypervisor_type = string<br/>      ip              = string<br/>      username        = string<br/>      password        = string<br/>    }), null)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lcm_current_entity_versions"></a> [lcm\_current\_entity\_versions](#output\_lcm\_current\_entity\_versions) | Current versions of entities before upgrade |
| <a name="output_lcm_entities_summary"></a> [lcm\_entities\_summary](#output\_lcm\_entities\_summary) | Summary of entities configured vs entities with updates |
| <a name="output_prism_central_entities_to_upgrade"></a> [prism\_central\_entities\_to\_upgrade](#output\_prism\_central\_entities\_to\_upgrade) | Configured entities to upgrade for Prism Central |
| <a name="output_prism_central_entities_with_updates"></a> [prism\_central\_entities\_with\_updates](#output\_prism\_central\_entities\_with\_updates) | Prism Central entities that have available updates |
| <a name="output_prism_central_entity_versions_after_upgrade"></a> [prism\_central\_entity\_versions\_after\_upgrade](#output\_prism\_central\_entity\_versions\_after\_upgrade) | Prism Central entity versions after upgrade |
| <a name="output_prism_central_lcm_entities"></a> [prism\_central\_lcm\_entities](#output\_prism\_central\_lcm\_entities) | Raw LCM entities data for Prism Central |
| <a name="output_prism_central_matching_entities"></a> [prism\_central\_matching\_entities](#output\_prism\_central\_matching\_entities) | Prism Central entities that match configuration (may not have updates) |
| <a name="output_prism_element_cluster_entities_to_upgrade"></a> [prism\_element\_cluster\_entities\_to\_upgrade](#output\_prism\_element\_cluster\_entities\_to\_upgrade) | Configured entities to upgrade for each cluster |
| <a name="output_prism_element_cluster_entities_with_updates"></a> [prism\_element\_cluster\_entities\_with\_updates](#output\_prism\_element\_cluster\_entities\_with\_updates) | Cluster entities that have available updates |
| <a name="output_prism_element_cluster_lcm_entities"></a> [prism\_element\_cluster\_lcm\_entities](#output\_prism\_element\_cluster\_lcm\_entities) | Raw LCM entities data for each cluster |
| <a name="output_prism_element_cluster_lcm_status_after_upgrade"></a> [prism\_element\_cluster\_lcm\_status\_after\_upgrade](#output\_prism\_element\_cluster\_lcm\_status\_after\_upgrade) | LCM status after upgrade for each cluster |
| <a name="output_prism_element_cluster_matching_entities"></a> [prism\_element\_cluster\_matching\_entities](#output\_prism\_element\_cluster\_matching\_entities) | Cluster entities that match configuration (may not have updates) |
| <a name="output_prism_element_inventory_operations"></a> [prism\_element\_inventory\_operations](#output\_prism\_element\_inventory\_operations) | Inventory operation details for each Prism Element cluster |
| <a name="output_prism_element_lcm_configs"></a> [prism\_element\_lcm\_configs](#output\_prism\_element\_lcm\_configs) | LCM configuration details for each Prism Element cluster |
| <a name="output_prism_element_missing_cluster_validation"></a> [prism\_element\_missing\_cluster\_validation](#output\_prism\_element\_missing\_cluster\_validation) | Validation data for missing clusters (triggers precondition check) |
| <a name="output_prism_element_precheck_operations"></a> [prism\_element\_precheck\_operations](#output\_prism\_element\_precheck\_operations) | Precheck operation details for each Prism Element cluster |
| <a name="output_prism_element_summary"></a> [prism\_element\_summary](#output\_prism\_element\_summary) | Summary of LCM operations across all Prism Element clusters |
| <a name="output_prism_element_upgrade_operations"></a> [prism\_element\_upgrade\_operations](#output\_prism\_element\_upgrade\_operations) | Upgrade operation details for each Prism Element cluster |
<!-- END_TF_DOCS -->
