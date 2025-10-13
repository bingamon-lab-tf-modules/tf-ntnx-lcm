output "cluster_lcm_configs" {
  description = "LCM configuration details for each cluster"
  value = {
    for cluster_key, cluster_config in nutanix_lcm_config_v2.cluster_lcm_settings :
    cluster_key => {
      cluster_name                    = var.prism_element[cluster_key].name
      cluster_id                      = cluster_config.x_cluster_id
      connectivity_type               = cluster_config.connectivity_type
      darksite_url                    = cluster_config.url
      is_auto_inventory_enabled       = cluster_config.is_auto_inventory_enabled
      auto_inventory_schedule         = cluster_config.auto_inventory_schedule
      is_https_enabled                = cluster_config.is_https_enabled
      has_module_auto_upgrade_enabled = cluster_config.has_module_auto_upgrade_enabled
    }
  }
}

output "inventory_operations" {
  description = "Inventory operation details for each cluster"
  value = {
    for cluster_key, inventory in nutanix_lcm_perform_inventory_v2.cluster_inventory :
    cluster_key => {
      cluster_name = var.prism_element[cluster_key].name
      cluster_id   = inventory.x_cluster_id
    }
  }
}

output "precheck_operations" {
  description = "Precheck operation details for each cluster"
  value = {
    for cluster_key, precheck in nutanix_lcm_prechecks_v2.cluster_prechecks :
    cluster_key => {
      cluster_name = var.prism_element[cluster_key].name
      cluster_id   = precheck.x_cluster_id
      operation_id = precheck.ext_id
    }
  }
}

output "upgrade_operations" {
  description = "Upgrade operation details for each cluster"
  value = {
    for cluster_key, upgrade in nutanix_lcm_upgrade_v2.cluster_upgrade :
    cluster_key => {
      cluster_name = var.prism_element[cluster_key].name
      cluster_id   = upgrade.x_cluster_id
    }
  }
}

output "summary" {
  description = "Summary of LCM operations across all clusters"
  value = {
    total_clusters     = length(var.prism_element)
    inventory_clusters = length(local.inventory_clusters)
    precheck_clusters  = length(local.precheck_clusters)
    upgrade_clusters   = length(local.upgrade_clusters)
    non_ahv_clusters   = local.non_ahv_clusters
    darksite_clusters  = [for k, v in var.prism_element : v.name if v.connectivity_type == "DARKSITE_WEB_SERVER"]
  }
}

output "current_entity_versions" {
  description = "Current versions of entities before upgrade"
  value       = local.current_entity_versions
}

output "prism_central_lcm_entities" {
  description = "Raw LCM entities data for Prism Central"
  value       = data.nutanix_lcm_entities_v2.prism_central_lcm_entities
}

output "cluster_lcm_entities" {
  description = "Raw LCM entities data for each cluster"
  value       = data.nutanix_lcm_entities_v2.cluster_lcm_entities
}

output "prism_central_entities_to_upgrade" {
  description = "Configured entities to upgrade for Prism Central"
  value       = var.prism_central.entities_to_upgrade
}

output "cluster_entities_to_upgrade" {
  description = "Configured entities to upgrade for each cluster"
  value       = { for k, v in var.prism_element : k => v.entities_to_upgrade }
}

output "prism_central_matching_entities" {
  description = "Prism Central entities that match configuration (may not have updates)"
  value       = local.prism_central_matching_entities
}

output "prism_central_entities_with_updates" {
  description = "Prism Central entities that have available updates"
  value       = local.prism_central_entities_with_updates
}

output "cluster_matching_entities" {
  description = "Cluster entities that match configuration (may not have updates)"
  value       = local.cluster_matching_entities
}

output "cluster_entities_with_updates" {
  description = "Cluster entities that have available updates"
  value       = local.cluster_entities_with_updates
}

output "entities_summary" {
  description = "Summary of entities configured vs entities with updates"
  value = {
    prism_central = {
      configured_count   = length(local.prism_central_matching_entities)
      with_updates_count = length(local.prism_central_entities_with_updates)
      will_run_prechecks = var.prism_central.perform_prechecks && length(local.prism_central_entities_with_updates) > 0
      will_run_upgrade   = var.prism_central.perform_upgrade && length(local.prism_central_entities_with_updates) > 0
    }
    clusters = {
      for k, v in var.prism_element : k => {
        configured_count   = length(local.cluster_matching_entities[k])
        with_updates_count = length(local.cluster_entities_with_updates[k])
        will_run_prechecks = v.perform_prechecks && length(local.cluster_entities_with_updates[k]) > 0
        will_run_upgrade   = v.perform_upgrade && length(local.cluster_entities_with_updates[k]) > 0
      }
    }
  }
}

output "prism_central_entity_versions_after_upgrade" {
  description = "Prism Central entity versions after upgrade"
  value       = data.nutanix_lcm_entity_v2.prism_central_entities_after_upgrade
}

output "cluster_lcm_status_after_upgrade" {
  description = "LCM status after upgrade for each cluster"
  value       = data.nutanix_lcm_status_v2.cluster_status_after_upgrade
}

output "missing_cluster_validation" {
  description = "Validation data for missing clusters (triggers precondition check)"
  value       = data.local_file.missing_cluster_check.content
}
