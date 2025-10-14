# Only AHV clusters are supported.
# For any other cluster, throw an error.
check "prism_element_ahv_only" {
  assert {
    condition     = length(local.prism_element_non_ahv_clusters) == 0
    error_message = "Only AHV clusters are supported. Non-AHV clusters found: ${join(", ", local.prism_element_non_ahv_clusters)}"
  }
}

# DarkSite clusters require a URL.
check "prism_element_lcm_url_required_for_darksite" {
  assert {
    condition     = length(local.prism_element_darksite_clusters_without_url) == 0
    error_message = "LCM DarkSite URL is required for clusters with DARKSITE_WEB_SERVER connectivity mode. Affected clusters: ${join(", ", local.prism_element_darksite_clusters_without_url)}"
  }
}
