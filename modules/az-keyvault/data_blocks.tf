/* Fetches details of current authenticated user/service principal (tenant_id, object_id)
Used for access policies and resource configuration */
data "azurerm_client_config" "current" {}

/* Fetches existing storage account details (used for Key Vault diagnostics);
Use when referencing already created resources instead of creating new ones */
data "azurerm_storage_account" "kv_audit" {
  name                = var.audit_storage_account_name
  resource_group_name = var.audit_storage_account_rg
}