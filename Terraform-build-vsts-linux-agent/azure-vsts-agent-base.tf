
#-------------------------------------------------------
# Stetment of Resource Group
#-------------------------------------------------------
resource "azurerm_resource_group" "vsts-agent-linux" {
  name     = "001-decode2018-vsts-agent-linux"
  location = "Japan East"
}

#-------------------------------------------------------
# Creating Networking 
#-------------------------------------------------------
resource "azurerm_virtual_network" "vsts-agent-linux" {
  name                = "prod-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.vsts-agent-linux.location}"
  resource_group_name = "${azurerm_resource_group.vsts-agent-linux.name}"
}

resource "azurerm_subnet" "vsts-agent-linux" {
  name                 = "vsts-agent-linux-subnet"
  resource_group_name  = "${azurerm_resource_group.vsts-agent-linux.name}"
  virtual_network_name = "${azurerm_virtual_network.vsts-agent-linux.name}"
  address_prefix       = "10.0.0.0/24"
}

resource "azurerm_public_ip" "vsts-agent-linux" {
  name                         = "VSTSAgentPublicIP"
  location                     = "${azurerm_resource_group.vsts-agent-linux.location}"
  resource_group_name          = "${azurerm_resource_group.vsts-agent-linux.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "vsts-agent-linux" {
  name                = "vsts-agent-linux-nic"  
  location            = "${azurerm_resource_group.vsts-agent-linux.location}"
  resource_group_name = "${azurerm_resource_group.vsts-agent-linux.name}"

  ip_configuration {
    name                          = "VSTSAgentPIPConfiguration"
    subnet_id                     = "${azurerm_subnet.vsts-agent-linux.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.vsts-agent-linux.id}"
  }
}

#-------------------------------------------------------
# Creating Storage
#-------------------------------------------------------

resource "azurerm_managed_disk" "vsts-agent-linux" {
  name                 = "vsts-agent-linux_datadisk"
  location             = "${azurerm_resource_group.vsts-agent-linux.location}"
  resource_group_name  = "${azurerm_resource_group.vsts-agent-linux.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"
}

#-------------------------------------------------------
# Creating Compute
#-------------------------------------------------------

resource "azurerm_availability_set" "vsts-agent-linux" {
  name                         = "vsts-agent-linux"
  location                     = "${azurerm_resource_group.vsts-agent-linux.location}"
  resource_group_name          = "${azurerm_resource_group.vsts-agent-linux.name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

resource "azurerm_virtual_machine" "vsts-agent-linux" {
  name                  = "vsts-agent-linux-vm"
  location              = "${azurerm_resource_group.vsts-agent-linux.location}"
  availability_set_id   = "${azurerm_availability_set.vsts-agent-linux.id}"
  resource_group_name   = "${azurerm_resource_group.vsts-agent-linux.name}"
  network_interface_ids = ["${azurerm_network_interface.vsts-agent-linux.id}"]
  vm_size               = "Standard_DS5_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "vsts-agent-linux-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  # Optional data disks
  storage_data_disk {
    name              = "vsts-agent-linux-datadisk"
    managed_disk_type = "Premium_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "1023"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.vsts-agent-linux.name}"
    managed_disk_id = "${azurerm_managed_disk.vsts-agent-linux.id}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "${azurerm_managed_disk.vsts-agent-linux.disk_size_gb}"
  }

    os_profile {
        computer_name  = "vsts-agent-linux"
        admin_username = "kyoheim"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/kyoheim/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0vdCDoDEqy7ltyPVPUViF9w13nzC7j23I8hlHy03AtboNXmLNhVPmTV+sjSmujcCkDIzcSH312qUVxaUFJxdtzvPrudcQkHY2sx4A0ToYptiYT9phmlt8NJ7Kk0fXIGfzWoV4TPRCVfrNj7BT7CdsliOAp8zhQQuaN+Lm+0obRUiS1SGsWmGAwKgdV36EIykIIXa9Hux3wcPa7jfzlyXAJ4Np47o/LYNIZJBk3PbneUfJquns18aBN2CFVqTreXHNJIEgAhjAU+WCMqCsam0HIm04gZylHosjgL73jDihNTJuI4IEMApNcqzKceveVSaA4E9cjdq0JHd8VpbxDR59 kyoheim@fareast@DESKTOP-5P62V24"
        }
    }
  tags {
    environment = "management"
  }
}