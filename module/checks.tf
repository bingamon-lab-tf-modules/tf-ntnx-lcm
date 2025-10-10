# Only AHV clusters are supported.
# For any other cluster, throw an error.
check "ahv_only" {
  assert {
    condition     = length(local.non_ahv_clusters) == 0
    error_message = "Only AHV clusters are supported. Non-AHV clusters found: ${join(", ", local.non_ahv_clusters)}"
  }
}

# DarkSite clusters require a URL.
check "lcm_url_required_for_darksite" {
  assert {
    condition     = length(local.darksite_clusters_without_url) == 0
    error_message = "LCM DarkSite URL is required for clusters with DARKSITE_WEB_SERVER connectivity mode. Affected clusters: ${join(", ", local.darksite_clusters_without_url)}"
  }
}
