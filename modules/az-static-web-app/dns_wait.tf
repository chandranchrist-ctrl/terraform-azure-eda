# Adds delay to allow CNAME DNS propagation before Static Web App custom domain validation
resource "time_sleep" "wait_for_cname_dns" {

  depends_on = [
    null_resource.cname_dns
  ]

  create_duration = "90s"
}

# Adds delay to allow Traffic Manager validation DNS propagation before proceeding with domain binding
resource "time_sleep" "wait_for_tm_validation_dns" {

  count = var.tm_custom_domain != null ? 1 : 0

  depends_on = [
    null_resource.tm_validation_dns
  ]

  create_duration = "90s"
}

# Adds delay to allow SSL certificate provisioning for Traffic Manager custom domain
resource "time_sleep" "wait_for_tm_ssl" {

  count = var.tm_custom_domain != null ? 1 : 0

  depends_on = [
    azurerm_static_web_app_custom_domain.tm_domain[0]
  ]

  create_duration = "30s"
}