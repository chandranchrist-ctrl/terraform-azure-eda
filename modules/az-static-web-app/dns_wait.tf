# Wait for CNAME DNS Propagation
resource "time_sleep" "wait_for_cname_dns" {

  depends_on = [
    null_resource.cname_dns
  ]

  create_duration = "90s"
}