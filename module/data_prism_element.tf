# Fatal validation if clusters are missing
# This is to make sure the user has provided a valid name
# to avoid a footgun situation.
data "local_file" "missing_cluster_check" {
  filename = "/dev/null"
  lifecycle {
    precondition {
      condition     = length(local.missing_clusters) == 0
      error_message = "ERROR: The following configured clusters were not found in Nutanix - deployment has been aborted: ${jsonencode(local.missing_clusters)}"
    }
  }
}

# Lookup all cluster details and filter by name.
data "nutanix_clusters_v2" "clusters" {
  for_each = toset(local.cluster_names)

  limit  = 1
  filter = "name eq '${each.value}'"
}

# Lookup all LCM entities by cluster extID.
data "nutanix_lcm_entities_v2" "cluster_lcm_entities" {
  for_each = toset(local.cluster_names)

  filter = "clusterExtId eq '${data.nutanix_clusters_v2.clusters[each.key].cluster_entities[0].ext_id}'"
}

# Capture the versions before any upgrade
data "nutanix_lcm_entity_v2" "cluster_entity_before_upgrade" {
  for_each = { for ent in flatten([for cluster in local.cluster_names : [for e in data.nutanix_lcm_entities_v2.cluster_lcm_entities[cluster].entities : { cluster = cluster, ext_id = e.ext_id, model = e.entity_model }]]) : "${ent.cluster}-${ent.ext_id}" => ent }

  ext_id = each.value.ext_id
}

# Check if there is any operation in progress before prechecks.
data "nutanix_lcm_status_v2" "cluster_status_before_prechecks" {
  for_each = { for k, v in local.existing_clusters : k => v if v.perform_prechecks }

  x_cluster_id = local.cluster_data_map[each.value.name].ext_id

  lifecycle {
    postcondition {
      condition     = self.in_progress_operation[0].operation_type == "" && self.in_progress_operation[0].operation_id == ""
      error_message = "Operation in progress on cluster ${each.value.name}: ${self.in_progress_operation[0].operation_type}"
    }
  }
  depends_on = [nutanix_lcm_perform_inventory_v2.cluster_inventory]
}

# Check if there is any operation in progress before upgrade
data "nutanix_lcm_status_v2" "cluster_status_before_upgrade" {
  for_each = { for k, v in local.existing_clusters : k => v if v.perform_prechecks }

  x_cluster_id = local.cluster_data_map[each.value.name].ext_id

  lifecycle {
    postcondition {
      condition     = self.in_progress_operation[0].operation_type == "" && self.in_progress_operation[0].operation_id == ""
      error_message = "Operation in progress on cluster ${each.value.name}: ${self.in_progress_operation[0].operation_type}"
    }
  }
  depends_on = [nutanix_lcm_perform_inventory_v2.cluster_inventory]
}

# Check if there is any operation in progress after upgrade
data "nutanix_lcm_status_v2" "cluster_status_after_upgrade" {
  for_each = { for k, v in local.existing_clusters : k => v if v.perform_prechecks }

  x_cluster_id = local.cluster_data_map[each.value.name].ext_id

  lifecycle {
    postcondition {
      condition     = self.in_progress_operation[0].operation_type == "" && self.in_progress_operation[0].operation_id == ""
      error_message = "Operation in progress on cluster ${each.value.name}: ${self.in_progress_operation[0].operation_type}"
    }
  }
  depends_on = [
    nutanix_lcm_perform_inventory_v2.cluster_inventory,
    nutanix_lcm_upgrade_v2.cluster_upgrade
  ]
}
