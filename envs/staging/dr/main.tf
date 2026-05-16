terraform {
  backend "local" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.67.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "e5e41cc7-7577-47be-a02d-3294887037d2"

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

module "mssql_failover_group" {
  source = "../../../modules/az-compute/rds/mssql-failover-group"

  failover_group_name = "dr-eda-fog"

  primary_sql_server_name         = "ci-uat-eda-sql1"
  primary_sql_resource_group_name = "ci-uat-rg"
  primary_database_name           = "ci_uat_eda_db1"

  secondary_sql_server_name         = "si-dr-eda-sql1-dr"
  secondary_sql_resource_group_name = "si-dr-rg"
}