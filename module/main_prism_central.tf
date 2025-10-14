##################################################
# LCM for Prism Central
##################################################

# 1. Configure LCM settings for Prism Central
resource "nutanix_lcm_config_v2" "prism_central_lcm_settings" {
  x_cluster_id = local.prism_central_id

  connectivity_type               = var.prism_central.connectivity_type
  url                             = var.prism_central.darksite_url
  is_auto_inventory_enabled       = var.prism_central.is_auto_inventory_enabled
  auto_inventory_schedule         = var.prism_central.auto_inventory_schedule
  is_https_enabled                = var.prism_central.is_https_enabled
  has_module_auto_upgrade_enabled = var.prism_central.has_module_auto_upgrade_enabled

  depends_on = [
    data.nutanix_clusters_v2.prism_central_cluster
  ]
}

# 2. Perform inventory action for Prism Central (if enabled)
resource "nutanix_lcm_perform_inventory_v2" "prism_central_inventory" {
  count = var.prism_central.perform_inventory ? 1 : 0

  x_cluster_id = local.prism_central_id

  depends_on = [
    nutanix_lcm_config_v2.prism_central_lcm_settings
  ]
}

# 3. Perform upgrade pre-checks for Prism Central (if enabled)
resource "nutanix_lcm_prechecks_v2" "prism_central_prechecks" {
  count = var.prism_central.perform_prechecks && length(local.prism_central_entities_with_updates) > 0 ? 1 : 0

  x_cluster_id = local.prism_central_id

  dynamic "entity_update_specs" {
    for_each = { for ent in local.prism_central_entities_with_updates : ent.ext_id => ent }
    content {
      entity_uuid = entity_update_specs.key # The entity's UUID
      to_version = var.prism_central.entities_to_upgrade[entity_update_specs.value.entity_model].target_version == "latest" ? (
        length(entity_update_specs.value.available_versions) > 0 ? entity_update_specs.value.available_versions[length(entity_update_specs.value.available_versions) - 1].version : entity_update_specs.value.entity_version
      ) : var.prism_central.entities_to_upgrade[entity_update_specs.value.entity_model].target_version
    }
  }

  dynamic "management_server" {
    for_each = var.prism_central.management_server != null ? [var.prism_central.management_server] : []
    content {
      hypervisor_type = management_server.value.hypervisor_type
      ip              = management_server.value.ip
      username        = management_server.value.username
      password        = management_server.value.password
    }
  }

  depends_on = [
    nutanix_lcm_perform_inventory_v2.prism_central_inventory,
    data.nutanix_lcm_entities_v2.prism_central_lcm_entities,
    data.nutanix_lcm_entity_v2.prism_central_lcm_entities_before_upgrade,
    data.nutanix_lcm_status_v2.prism_central_lcm_status_before_prechecks
  ]
}

# 4. Perform upgrade action for Prism Central (if enabled)
resource "nutanix_lcm_upgrade_v2" "prism_central_upgrade" {
  count = var.prism_central.perform_upgrade && length(local.prism_central_entities_with_updates) > 0 ? 1 : 0

  x_cluster_id = local.prism_central_id

  skipped_precheck_flags = var.prism_central.skipped_precheck_flags
  auto_handle_flags      = var.prism_central.auto_handle_flags
  max_wait_time_in_secs  = var.prism_central.max_wait_time_in_secs

  dynamic "entity_update_specs" {
    for_each = { for ent in local.prism_central_entities_with_updates : ent.ext_id => ent }
    content {
      entity_uuid = entity_update_specs.key # The entity's UUID
      to_version = var.prism_central.entities_to_upgrade[entity_update_specs.value.entity_model].target_version == "latest" ? (
        length(entity_update_specs.value.available_versions) > 0 ? entity_update_specs.value.available_versions[length(entity_update_specs.value.available_versions) - 1].version : entity_update_specs.value.entity_version
      ) : var.prism_central.entities_to_upgrade[entity_update_specs.value.entity_model].target_version
    }
  }

  dynamic "management_server" {
    for_each = var.prism_central.management_server != null ? [var.prism_central.management_server] : []
    content {
      hypervisor_type = management_server.value.hypervisor_type
      ip              = management_server.value.ip
      username        = management_server.value.username
      password        = management_server.value.password
    }
  }

  depends_on = [
    nutanix_lcm_prechecks_v2.prism_central_prechecks,
    data.nutanix_lcm_status_v2.prism_central_lcm_status_before_upgrade
  ]
}
