locals {

  ##################################################
  # Prism Central
  ##################################################

  # Extract the Prism Central ID
  prism_central_id = data.nutanix_clusters_v2.prism_central_cluster.cluster_entities[0].ext_id

  # Further filter out the LCM entities, removing any Prism Element clusters.
  prism_central_lcm_entities_filtered = [
    for entity in data.nutanix_lcm_entities_v2.prism_central_lcm_entities.entities : entity
    if !contains(local.prism_element_cluster_names, entity.device_id)
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

  ##################################################
  # Prism Element
  ##################################################

  # Cluster names.
  prism_element_cluster_names = [for k, v in var.prism_element : v.name]

  # Map cluster names to var.prism_element keys
  prism_element_cluster_name_to_key = { for k, v in var.prism_element : v.name => k }

  # Non-AHV clusters - using correct v2 API structure
  prism_element_non_ahv_clusters = [
    for cluster_name, cluster_data in data.nutanix_clusters_v2.prism_element_cluster :
    cluster_name
    if length(cluster_data.cluster_entities) > 0 &&
    try(cluster_data.cluster_entities[0].config[0].hypervisor_types[0], null) != "AHV"
  ]

  # Compute missing clusters for validation
  prism_element_missing_clusters = [
    for cluster_name in local.prism_element_cluster_names :
    cluster_name if !contains(keys(local.prism_element_cluster_data_map), cluster_name)
  ]

  # Filter to only contain clusters that actually exist.
  prism_element_existing_clusters = { for k, v in var.prism_element : k => v if contains(keys(local.prism_element_cluster_data_map), v.name) }

  # DarkSite clusters without a URL.
  prism_element_darksite_clusters_without_url = [
    for k, v in var.prism_element :
    v.name if v.connectivity_type == "DARKSITE_WEB_SERVER" && (v.darksite_url == null || v.darksite_url == "")
  ]

  # Filter for clusters where inventory should be performed
  prism_element_inventory_clusters = { for k, v in var.prism_element : k => v if v.perform_inventory }

  # Filter for clusters where pre-checks should be performed
  prism_element_precheck_clusters = { for k, v in var.prism_element : k => v if v.perform_prechecks }

  # Filter for clusters where an upgrade should be performed
  prism_element_upgrade_clusters = { for k, v in var.prism_element : k => v if v.perform_upgrade }

  # Create a map of cluster names to their cluster entities for easy lookup
  # Based on nutanix_clusters_v2 structure - cluster data is in cluster_entities[0]
  prism_element_cluster_data_map = {
    for cluster_name, cluster_data in data.nutanix_clusters_v2.prism_element_cluster :
    cluster_name => try(cluster_data.cluster_entities[0], null)
    if length(cluster_data.cluster_entities) > 0
  }

  # Matching entities for each Prism Element cluster that are configured for upgrade
  prism_element_cluster_matching_entities = {
    for cluster_name, ents in data.nutanix_lcm_entities_v2.prism_element_lcm_entities :
    local.prism_element_cluster_name_to_key[cluster_name] => [
      for ent in ents.entities :
      ent
      if ent.cluster_ext_id == local.prism_element_cluster_data_map[cluster_name].ext_id && contains(keys(var.prism_element[local.prism_element_cluster_name_to_key[cluster_name]].entities_to_upgrade), ent.entity_model)
    ]
  }

  # Cluster entities that have available updates (not just configured)
  prism_element_cluster_entities_with_updates = {
    for k, ents in local.prism_element_cluster_matching_entities :
    k => [
      for ent in ents :
      ent
      if length(ent.available_versions) > 0
    ]
  }

  ##################################################
  # Common
  ##################################################

  # TODO: Merge all software entities into a single local map.
  lcm_current_entity_versions = merge(
    {
      # Prism Central versions before upgrade.
      for key, ent in data.nutanix_lcm_entity_v2.prism_central_lcm_entities_before_upgrade : "prism_central-${key}" => {
        cluster         = "prism_central"
        entity_uuid     = key
        entity_model    = ent.entity_model
        current_version = ent.entity_version
      }
    },
    {
      # Prism Element versions before upgrade.
      for key, ent in data.nutanix_lcm_entity_v2.prism_element_lcm_entities_before_upgrade : key => {
        cluster         = split("-", key)[0]
        entity_uuid     = split("-", key)[1]
        entity_model    = ent.entity_model
        current_version = ent.entity_version
      }
    }
  )
}
