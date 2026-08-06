##################################################
# Data Lookups for Prism Central
##################################################

# Lookup Prism Central cluster
data "nutanix_clusters_v2" "prism_central_cluster" {
  limit  = 1
  filter = "config/clusterFunction/any(t:t eq Clustermgmt.Config.ClusterFunctionRef'PRISM_CENTRAL')" # v2.2.1
}

# Lookup all LCM entities by cluster extID.
data "nutanix_lcm_entities_v2" "prism_central_lcm_entities" {
  filter = "clusterExtId eq '${data.nutanix_clusters_v2.prism_central_cluster.cluster_entities[0].ext_id}'"
}

# Capture the versions before any upgrade.
data "nutanix_lcm_entity_v2" "prism_central_lcm_entities_before_upgrade" {
  for_each = { for entity in local.prism_central_lcm_entities_filtered : entity.ext_id => { ext_id = entity.ext_id, model = entity.entity_model } }

  ext_id = each.value.ext_id
}

# Check if there is any operation in progress before prechecks.
data "nutanix_lcm_status_v2" "prism_central_lcm_status_before_prechecks" {
  count = var.prism_central.perform_prechecks ? 1 : 0

  x_cluster_id = local.prism_central_id

  lifecycle {
    postcondition {
      condition     = self.in_progress_operation[0].operation_type == "" && self.in_progress_operation[0].operation_id == ""
      error_message = "Operation is in progress on prism central: ${self.in_progress_operation[0].operation_type}"
    }
  }
  depends_on = [
    nutanix_lcm_perform_inventory_v2.prism_central_inventory
  ]
}

# Check if there is any operation in progress before upgrade
data "nutanix_lcm_status_v2" "prism_central_lcm_status_before_upgrade" {
  count = var.prism_central.perform_upgrade ? 1 : 0

  x_cluster_id = local.prism_central_id

  lifecycle {
    postcondition {
      condition     = self.in_progress_operation[0].operation_type == "" && self.in_progress_operation[0].operation_id == ""
      error_message = "Operation is in progress on prism central: ${self.in_progress_operation[0].operation_type}"
    }
  }
  depends_on = [
    nutanix_lcm_perform_inventory_v2.prism_central_inventory
  ]
}

# Check if there is any operation in progress after upgrade
data "nutanix_lcm_status_v2" "prism_central_lcm_status_after_upgrade" {
  count = var.prism_central.perform_upgrade ? 1 : 0

  x_cluster_id = local.prism_central_id

  lifecycle {
    postcondition {
      condition     = self.in_progress_operation[0].operation_type == "" && self.in_progress_operation[0].operation_id == ""
      error_message = "operation is in progress on prism central: ${self.in_progress_operation[0].operation_type}"
    }
  }
  depends_on = [
    nutanix_lcm_perform_inventory_v2.prism_central_inventory,
    nutanix_lcm_upgrade_v2.prism_central_upgrade
  ]
}

# TODO: Finally, check the versions before and after for all prism_central.entities_to_upgrade
# Verify entity versions after upgrade
data "nutanix_lcm_entity_v2" "prism_central_lcm_entities_after_upgrade" {
  # expected_version resolves "latest" the same way the upgrade itself did — by
  # the API's `order` ranking (see locals.tf), not by list position. Reading it
  # positionally here also yielded the whole available_version object rather
  # than its .version, so the postcondition below compared a string to an
  # object and could never pass.
  for_each = {
    for entity in local.prism_central_lcm_entities_filtered :
    entity.ext_id => {
      ext_id = entity.ext_id
      model  = entity.entity_model
      expected_version = (
        var.prism_central.entities_to_upgrade[entity.entity_model].target_version == "latest"
        ? local.lcm_latest_version_by_entity[entity.ext_id]
        : var.prism_central.entities_to_upgrade[entity.entity_model].target_version
      )
    }
    if var.prism_central.perform_upgrade
    && contains(keys(var.prism_central.entities_to_upgrade), entity.entity_model)
    && length(entity.available_versions) > 0
  }

  ext_id = each.value.ext_id

  lifecycle {
    postcondition {
      condition     = self.entity_version == each.value.expected_version
      error_message = "Entity not upgraded to expected version ${each.value.expected_version}, current version: ${self.entity_version}"
    }
    postcondition {
      condition     = self.entity_model == each.value.model
      error_message = "Entity model changed, current model: ${self.entity_model}"
    }
    postcondition {
      condition     = self.entity_version != data.nutanix_lcm_entity_v2.prism_central_lcm_entities_before_upgrade[each.key].entity_version
      error_message = "Entity version did not change after upgrade"
    }
  }
  depends_on = [
    nutanix_lcm_upgrade_v2.prism_central_upgrade,
    data.nutanix_lcm_status_v2.prism_central_lcm_status_after_upgrade
  ]
}
