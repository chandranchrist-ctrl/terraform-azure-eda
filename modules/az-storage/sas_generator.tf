data "azurerm_storage_account_sas" "sas" {
  count = var.enable_sas ? 1 : 0

  connection_string = azurerm_storage_account.storage_account.primary_connection_string

  https_only = true

  # start  = timestamp()
  # expiry = timeadd(timestamp(), "8760h")

  start  = timeadd(timestamp(), "-15m")
  expiry = timeadd(timestamp(), "8760h")

  resource_types {
    service   = true
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  permissions {
    read    = true
    write   = true
    delete  = true
    list    = true
    add     = true
    create  = true
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}