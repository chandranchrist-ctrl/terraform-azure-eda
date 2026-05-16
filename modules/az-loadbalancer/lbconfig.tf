locals {
  # PROBES
  probes = [
    {
      name                = "uat-eda-vmss-http-probe"
      protocol            = "Tcp"
      port                = 80
      interval_in_seconds = 5
      number_of_probes    = 2
      # request_path = "/"
    },
    {
      name                = "uat-eda-vmss-https-probe"
      protocol            = "Tcp"
      port                = 443
      interval_in_seconds = 5
      number_of_probes    = 2
      #request_path = "/"
    }
  ]

  # LB RULES
  lb_rules = [
    {
      name          = "uat-eda-vmss-http-api"
      protocol      = "Tcp"
      frontend_port = 80
      backend_port  = 80
      probe_name    = "uat-eda-vmss-http-probe"
    },
    {
      name          = "uat-eda-vmss-https-api"
      protocol      = "Tcp"
      frontend_port = 443
      backend_port  = 443
      probe_name    = "uat-eda-vmss-https-probe"
    }
  ]
}