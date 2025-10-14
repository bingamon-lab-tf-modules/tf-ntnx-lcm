##################################################
# LCM for Prism Element
##################################################

# 1. Configure LCM settings for Prism Element
resource "nutanix_lcm_config_v2" "cluster_lcm_settings" {
  for_each = local.prism_element_existing_clusters

  x_cluster_id = local.prism_element_cluster_data_map[each.value.name].ext_id

  connectivity_type               = each.value.connectivity_type
  url                             = each.value.darksite_url
  is_auto_inventory_enabled       = each.value.is_auto_inventory_enabled
  auto_inventory_schedule         = each.value.auto_inventory_schedule
  is_https_enabled                = each.value.is_https_enabled
  has_module_auto_upgrade_enabled = each.value.has_module_auto_upgrade_enabled

  depends_on = [
    data.nutanix_clusters_v2.clusters
  ]
}

# 2. Perform inventory action for Prism Element (if enabled)
resource "nutanix_lcm_perform_inventory_v2" "cluster_inventory" {
  for_each = { for k, v in local.prism_element_existing_clusters : k => v if v.perform_inventory }

  x_cluster_id = local.prism_element_cluster_data_map[each.value.name].ext_id

  depends_on = [
    nutanix_lcm_config_v2.cluster_lcm_settings
  ]
}

# 3. Perform upgrade pre-checks for Prism Element (if enabled)
resource "nutanix_lcm_prechecks_v2" "cluster_prechecks" {
  for_each = { for k, v in local.prism_element_existing_clusters : k => v if v.perform_prechecks && length(local.prism_element_cluster_entities_with_updates[k]) > 0 }

  x_cluster_id = local.prism_element_cluster_data_map[each.value.name].ext_id

  dynamic "entity_update_specs" {
    for_each = { for ent in local.prism_element_cluster_entities_with_updates[each.key] : ent.ext_id => ent }
    content {
      entity_uuid = entity_update_specs.key # The entity's UUID
      to_version = each.value.entities_to_upgrade[entity_update_specs.value.entity_model].target_version == "latest" ? (
        length(entity_update_specs.value.available_versions) > 0 ? entity_update_specs.value.available_versions[length(entity_update_specs.value.available_versions) - 1].version : entity_update_specs.value.entity_version
      ) : each.value.entities_to_upgrade[entity_update_specs.value.entity_model].target_version
    }
  }

  dynamic "management_server" {
    for_each = each.value.management_server != null ? [each.value.management_server] : []
    content {
      hypervisor_type = management_server.value.hypervisor_type
      ip              = management_server.value.ip
      username        = management_server.value.username
      password        = management_server.value.password
    }
  }

  depends_on = [
    nutanix_lcm_perform_inventory_v2.cluster_inventory,
    data.nutanix_lcm_entities_v2.cluster_lcm_entities,
    data.nutanix_lcm_entity_v2.cluster_entity_before_upgrade,
    data.nutanix_lcm_status_v2.cluster_status_before_prechecks
  ]
}

# 4. Perform upgrade action for Prism Element (if enabled)
resource "nutanix_lcm_upgrade_v2" "cluster_upgrade" {
  for_each = { for k, v in local.prism_element_existing_clusters : k => v if v.perform_upgrade && length(local.prism_element_cluster_entities_with_updates[k]) > 0 }

  x_cluster_id = local.prism_element_cluster_data_map[each.value.name].ext_id

  skipped_precheck_flags = each.value.skipped_precheck_flags
  auto_handle_flags      = each.value.auto_handle_flags
  max_wait_time_in_secs  = each.value.max_wait_time_in_secs

  dynamic "entity_update_specs" {
    for_each = { for ent in local.prism_element_cluster_entities_with_updates[each.key] : ent.ext_id => ent }
    content {
      entity_uuid = entity_update_specs.key # The entity's UUID
      to_version = each.value.entities_to_upgrade[entity_update_specs.value.entity_model].target_version == "latest" ? (
        length(entity_update_specs.value.available_versions) > 0 ? entity_update_specs.value.available_versions[length(entity_update_specs.value.available_versions) - 1].version : entity_update_specs.value.entity_version
      ) : each.value.entities_to_upgrade[entity_update_specs.value.entity_model].target_version
    }
  }

  dynamic "management_server" {
    for_each = each.value.management_server != null ? [each.value.management_server] : []
    content {
      hypervisor_type = management_server.value.hypervisor_type
      ip              = management_server.value.ip
      username        = management_server.value.username
      password        = management_server.value.password
    }
  }

  depends_on = [
    nutanix_lcm_prechecks_v2.cluster_prechecks,
    data.nutanix_lcm_status_v2.cluster_status_before_upgrade
  ]
}
