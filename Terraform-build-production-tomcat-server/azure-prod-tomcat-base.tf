
#-------------------------------------------------------
# Stetment of Resource Group
#-------------------------------------------------------
resource "azurerm_resource_group" "prod-tomcat" {
  name     = "001-decode2018-prod-tomcat"
  location = "Japan East"
}
resource "azurerm_managed_disk" "prod-tomcat" {
  name                 = "prod-tomcat-datadisk"
  location             = "${azurerm_resource_group.prod-tomcat.location}"
  resource_group_name  = "${azurerm_resource_group.prod-tomcat.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"
}
#-------------------------------------------------------
# Creating Networking 
#-------------------------------------------------------
resource "azurerm_virtual_network" "prod-tomcat" {
  name                = "prod-tomcat-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.prod-tomcat.location}"
  resource_group_name = "${azurerm_resource_group.prod-tomcat.name}"
}

resource "azurerm_subnet" "prod-tomcat" {
  name                 = "prod-tomcat-subnet"
  resource_group_name  = "${azurerm_resource_group.prod-tomcat.name}"
  virtual_network_name = "${azurerm_virtual_network.prod-tomcat.name}"
  address_prefix       = "10.0.2.0/24"
}


resource "azurerm_public_ip" "prod-tomcat" {
  name                         = "prodTomcatPublicIP"
  location                     = "${azurerm_resource_group.prod-tomcat.location}"
  resource_group_name          = "${azurerm_resource_group.prod-tomcat.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "prod-tomcat" {
  name                = "prod-tomcat-service-nic"
  location            = "${azurerm_resource_group.prod-tomcat.location}"
  resource_group_name = "${azurerm_resource_group.prod-tomcat.name}"

  ip_configuration {
    name                          = "ProdTomcatServicePIPConfiguration"
    subnet_id                     = "${azurerm_subnet.prod-tomcat.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.prod-tomcat.id}"
  }
}


#-------------------------------------------------------
# Creating Compute
#-------------------------------------------------------

resource "azurerm_availability_set" "prod-tomcat-as" {
  name                         = "prod-tomcat-as"
  location                     = "${azurerm_resource_group.prod-tomcat.location}"
  resource_group_name          = "${azurerm_resource_group.prod-tomcat.name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

resource "azurerm_virtual_machine" "prod-tomcat" {
  name                  = "prod-tomcat-vm"
  location              = "${azurerm_resource_group.prod-tomcat.location}"
  availability_set_id   = "${azurerm_availability_set.prod-tomcat-as.id}"
  resource_group_name   = "${azurerm_resource_group.prod-tomcat.name}"
  network_interface_ids = ["${azurerm_network_interface.prod-tomcat.id}"]
  vm_size               = "Standard_B1s"

  identity = {
    type = "SystemAssigned"
  }

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
    name              = "prod-tomcat-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  # Optional data disks
  storage_data_disk {
    name              = "prod-tomcat-datadisk-001"
    managed_disk_type = "Premium_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "1023"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.prod-tomcat.name}"
    managed_disk_id = "${azurerm_managed_disk.prod-tomcat.id}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "1023"
  }

    os_profile {
        computer_name  = "prod-tomcat"
        admin_username = "kyoheim"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/kyoheim/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCtWBhkiVVs0JCE+1VCw1a/o+I4H/7R2rTEbFlenpavtwCfmN0s0ptP5UfL/2ySHeKAMoEH7K8h3ggcv5tcmFlAlTPhTLiumGPjPjY0UK0DYaAXp1IKiJFNkmyNdvu1g34F1/onS/NN/2n+9o/cjNQ65VmYql+qBuOHpX34yLicnkNb48DSuehcJqNlG0qERynxMElCiqdrjjXj8YpdzGvY60dAVt7PTFGUKSjBsX2C8yYG5qVfhV490RTt0QyJw5/i/HB2xCirG4n5NK0VR+1tTfGJzH6laQfUNJFE9MdjNK69eGXgZnOo+5r+X494QyATWxTV39YbKALLVpfuAMjB kyoheim@vsts-agent-linux"
        }
    }
  tags {
    environment = "staging"
  }
}