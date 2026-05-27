locals {
  # Probes
  probes = [
    {
      name                = "eda-vmss-http-probe"
      protocol            = "Tcp"
      port                = 80
      interval_in_seconds = 5
      number_of_probes    = 2
      # request_path = "/"
    },
    {
      name                = "eda-vmss-https-probe"
      protocol            = "Tcp"
      port                = 443
      interval_in_seconds = 5
      number_of_probes    = 2
      #request_path = "/"
    }
  ]

  # LB Rules
  lb_rules = [
    {
      name          = "eda-vmss-http-api"
      protocol      = "Tcp"
      frontend_port = 80
      backend_port  = 80
      probe_name    = "eda-vmss-http-probe"
    },
    {
      name          = "eda-vmss-https-api"
      protocol      = "Tcp"
      frontend_port = 443
      backend_port  = 443
      probe_name    = "eda-vmss-https-probe"
    }
  ]
}