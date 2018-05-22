
#-------------------------------------------------------
# Statement of Resource Group
#-------------------------------------------------------
resource "azurerm_resource_group" "terraform-blob" {
  name     = "001-decode2018-terraform-state-blob"
  location = "Japan East"
}

#-------------------------------------------------------
# Creating starage blob / account and container
#------------------------------------------------------- 
resource "azurerm_storage_account" "terraform-blob" {
  name                     = "decodeterraformblob"
  resource_group_name      = "${azurerm_resource_group.terraform-blob.name}"
  location                 = "${azurerm_resource_group.terraform-blob.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "terraform-blob" {
  name                  = "terraformblobstatefile"
  resource_group_name   = "${azurerm_resource_group.terraform-blob.name}"
  storage_account_name  = "${azurerm_storage_account.terraform-blob.name}"
  container_access_type = "private"
}
