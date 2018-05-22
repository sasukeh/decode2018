
#-------------------------------------------------------
# Stetment of Resource Group
#-------------------------------------------------------
resource "azurerm_resource_group" "vsts-agent-windows" {
  name     = "001-decode2018-vsts-agent-win"
  location = "Japan East"
}

#-------------------------------------------------------
# Creating Networking 
#-------------------------------------------------------
resource "azurerm_virtual_network" "vsts-agent-windows" {
  name                = "vsts-agent-windows-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.vsts-agent-windows.location}"
  resource_group_name = "${azurerm_resource_group.vsts-agent-windows.name}"
}

resource "azurerm_subnet" "vsts-agent-windows" {
  name                 = "vsts-agent-windows-subnet"
  resource_group_name  = "${azurerm_resource_group.vsts-agent-windows.name}"
  virtual_network_name = "${azurerm_virtual_network.vsts-agent-windows.name}"
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_public_ip" "vsts-agent-windows" {
  name                         = "VSTSAgentWinPublicIP"
  location                     = "${azurerm_resource_group.vsts-agent-windows.location}"
  resource_group_name          = "${azurerm_resource_group.vsts-agent-windows.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "vsts-agent-windows" {
  name                = "vsts-agent-windows-nic"  
  location            = "${azurerm_resource_group.vsts-agent-windows.location}"
  resource_group_name = "${azurerm_resource_group.vsts-agent-windows.name}"

  ip_configuration {
    name                          = "VSTSAgentWINPIPConfiguration"
    subnet_id                     = "${azurerm_subnet.vsts-agent-windows.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.vsts-agent-windows.id}"
  }
}

#-------------------------------------------------------
# Creating Storage
#-------------------------------------------------------

resource "azurerm_managed_disk" "vsts-agent-windows" {
  name                 = "vsts-agent-windows_datadisk"
  location             = "${azurerm_resource_group.vsts-agent-windows.location}"
  resource_group_name  = "${azurerm_resource_group.vsts-agent-windows.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"
}

#-------------------------------------------------------
# Creating Compute
#-------------------------------------------------------

resource "azurerm_availability_set" "vsts-agent-windows" {
  name                         = "vsts-agent-windows-as"
  location                     = "${azurerm_resource_group.vsts-agent-windows.location}"
  resource_group_name          = "${azurerm_resource_group.vsts-agent-windows.name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

resource "azurerm_virtual_machine" "vsts-agent-windows" {
  name                  = "vsts-agent-windows-vm"
  location              = "${azurerm_resource_group.vsts-agent-windows.location}"
  availability_set_id   = "${azurerm_availability_set.vsts-agent-windows.id}"
  resource_group_name   = "${azurerm_resource_group.vsts-agent-windows.name}"
  network_interface_ids = ["${azurerm_network_interface.vsts-agent-windows.id}"]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "vsts-agent-windows-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  # Optional data disks
  storage_data_disk {
    name              = "vsts-agent-windows-datadisk"
    managed_disk_type = "Premium_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "1023"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.vsts-agent-windows.name}"
    managed_disk_id = "${azurerm_managed_disk.vsts-agent-windows.id}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "${azurerm_managed_disk.vsts-agent-windows.disk_size_gb}"
  }

  os_profile {
        computer_name  = "vsts-agent-win"
        admin_username = "kyoheim"
        admin_password = "Password1234!"
  }

  os_profile_windows_config {
        #dummy object/This must bu specified 
  }
  
  tags {
    environment = "management"
  }
}