resource "time_sleep" "wait_for_dns" {

  count = var.enable_external_dns && var.frontend_ip_type == "Public" ? 1 : 0

  depends_on = [
    null_resource.external_dns
  ]

  create_duration = "90s"
}