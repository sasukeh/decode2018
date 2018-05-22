terraform {
 backend "azurerm" {
  storage_account_name = "decodeterraformblob"
  container_name       = "terraformblobstatefile"
  key                  = "prod.terraform.tfstate"
  access_key           = ""
  }
}
