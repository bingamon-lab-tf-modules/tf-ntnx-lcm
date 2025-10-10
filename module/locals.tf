locals {
  # Extract the Prism Central ID
  prism_central_id = data.nutanix_clusters_v2.prism_central.cluster_entities[0].ext_id

  # Cluster names.
  cluster_names = [for k, v in var.clusters : v.name]

  # Non-AHV clusters - using correct v2 API structure
  non_ahv_clusters = [
    for cluster_name, cluster_data in data.nutanix_clusters_v2.clusters :
    cluster_name
    if length(cluster_data.cluster_entities) > 0 &&
    try(cluster_data.cluster_entities[0].config[0].hypervisor_types[0], null) != "AHV"
  ]

  # Compute missing clusters for validation
  missing_clusters = [
    for cluster_name in local.cluster_names :
    cluster_name if !contains(keys(local.cluster_data_map), cluster_name)
  ]

  # Filter to only contain clusters that actually exist.
  existing_clusters = { for k, v in var.clusters : k => v if contains(keys(local.cluster_data_map), v.name) }

  # DarkSite clusters without a URL.
  darksite_clusters_without_url = [
    for k, v in var.clusters :
    v.name if v.connectivity_type == "DARKSITE_WEB_SERVER" && (v.darksite_url == null || v.darksite_url == "")
  ]

  # Filter for clusters where inventory should be performed
  inventory_clusters = { for k, v in var.clusters : k => v if v.perform_inventory }

  # Filter for clusters where pre-checks should be performed
  precheck_clusters = { for k, v in var.clusters : k => v if v.perform_prechecks }

  # Filter for clusters where an upgrade should be performed
  upgrade_clusters = { for k, v in var.clusters : k => v if v.perform_upgrade }

  # Create a map of cluster names to their cluster entities for easy lookup
  # Based on nutanix_clusters_v2 structure - cluster data is in cluster_entities[0]
  cluster_data_map = {
    for cluster_name, cluster_data in data.nutanix_clusters_v2.clusters :
    cluster_name => try(cluster_data.cluster_entities[0], null)
    if length(cluster_data.cluster_entities) > 0
  }

  # Further filter out the LCM entities, removing any Prism Element clusters.
  prism_central_lcm_entities_filtered = [
    for entity in data.nutanix_lcm_entities_v2.prism_central_lcm_entities.entities : entity
    if !contains(local.cluster_names, entity.device_id)
  ]

  # Matching entities for Prism Central that are configured for upgrade
  prism_central_matching_entities = [
    for entity in local.prism_central_lcm_entities_filtered :
    entity
    if contains(keys(var.prism_central.entities_to_upgrade), entity.entity_model)
  ]

  # Prism Central entities that have available updates (not just configured)
  prism_central_entities_with_updates = [
    for entity in local.prism_central_matching_entities :
    entity
    if length(entity.available_versions) > 0
  ]

  # Matching entities for each Prism Central that are configured for upgrade
  cluster_matching_entities = {
    for k, ents in data.nutanix_lcm_entities_v2.cluster_lcm_entities :
    k => [
      for ent in ents.entities :
      ent
      if ent.cluster_ext_id == local.cluster_data_map[k].ext_id && contains(keys(var.clusters[k].entities_to_upgrade), ent.entity_model)
    ]
  }

  # Cluster entities that have available updates (not just configured)
  cluster_entities_with_updates = {
    for k, ents in local.cluster_matching_entities :
    k => [
      for ent in ents :
      ent
      if length(ent.available_versions) > 0
    ]
  }

  current_entity_versions = merge(
    {
      for key, ent in data.nutanix_lcm_entity_v2.cluster_entity_before_upgrade : key => {
        cluster         = split("-", key)[0]
        entity_uuid     = split("-", key)[1]
        entity_model    = ent.entity_model
        current_version = ent.entity_version
      }
    },
    {
      for key, ent in data.nutanix_lcm_entity_v2.prism_central_entities_before_upgrade : "prism_central-${key}" => {
        cluster         = "prism_central"
        entity_uuid     = key
        entity_model    = ent.entity_model
        current_version = ent.entity_version
      }
    }
  )
}
