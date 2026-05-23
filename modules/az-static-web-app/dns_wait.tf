# Wait for CNAME DNS Propagation (Default SWA Custom Domain)
resource "time_sleep" "wait_for_cname_dns" {

  depends_on = [
    null_resource.cname_dns
  ]

  create_duration = "90s"
}

# WAIT FOR DNS PROPAGATION (TM VALIDATION)
resource "time_sleep" "wait_for_tm_validation_dns" {

  count = var.tm_custom_domain != null ? 1 : 0

  depends_on = [
    null_resource.tm_validation_dns
  ]

  create_duration = "90s"
}

# WAIT FOR SSL
resource "time_sleep" "wait_for_tm_ssl" {

  count = var.tm_custom_domain != null ? 1 : 0

  depends_on = [
    azurerm_static_web_app_custom_domain.tm_domain[0]
  ]

  create_duration = "30s"
}