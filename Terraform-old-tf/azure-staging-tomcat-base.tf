
#-------------------------------------------------------
# Stetment of Resource Group
#-------------------------------------------------------
resource "azurerm_resource_group" "stage-tomcat" {
  name     = "001-decode2018-staging-tomcat"
  location = "Japan East"
}

#-------------------------------------------------------
# Creating Networking 
#-------------------------------------------------------
resource "azurerm_virtual_network" "stage-tomcat" {
  name                = "stage-tomcat-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.stage-tomcat.location}"
  resource_group_name = "${azurerm_resource_group.stage-tomcat.name}"
}

resource "azurerm_subnet" "stage-tomcat" {
  name                 = "stage-tomcat-subnet"
  resource_group_name  = "${azurerm_resource_group.stage-tomcat.name}"
  virtual_network_name = "${azurerm_virtual_network.stage-tomcat.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_subnet" "stage-tomcat-ansible" {
  name                 = "stage-tomcat-ansible-subnet"
  resource_group_name  = "${azurerm_resource_group.stage-tomcat.name}"
  virtual_network_name = "${azurerm_virtual_network.stage-tomcat.name}"
  address_prefix       = "10.0.3.0/24"
}

resource "azurerm_public_ip" "stage-tomcat" {
  name                         = "StageTomcatPublicIPForLB"
  location                     = "${azurerm_resource_group.stage-tomcat.location}"
  resource_group_name          = "${azurerm_resource_group.stage-tomcat.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_lb" "stage-tomcat" {
  name                = "stage-tomcat-loadBalancer"
  location            = "${azurerm_resource_group.stage-tomcat.location}"
  resource_group_name = "${azurerm_resource_group.stage-tomcat.name}"

  frontend_ip_configuration {
    name                 = "stage-tomcat-publicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.stage-tomcat.id}"
  }
}

resource "azurerm_lb_probe" "stage-tomcat" {
  resource_group_name = "${azurerm_resource_group.stage-tomcat.name}"
  loadbalancer_id     = "${azurerm_lb.stage-tomcat.id}"
  name                = "tomcat-running-probe"
  port                = 8080
}

resource "azurerm_lb_backend_address_pool" "stage-tomcat" {
  resource_group_name = "${azurerm_resource_group.stage-tomcat.name}"
  loadbalancer_id     = "${azurerm_lb.stage-tomcat.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_network_interface" "stage-tomcat" {
  count               = 2
  name                = "stage-tomcat-service-nic${count.index}"
  location            = "${azurerm_resource_group.stage-tomcat.location}"
  resource_group_name = "${azurerm_resource_group.stage-tomcat.name}"

  ip_configuration {
    name                          = "StageTomcatServicePIPConfiguration"
    subnet_id                     = "${azurerm_subnet.stage-tomcat.id}"
    private_ip_address_allocation = "dynamic"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.stage-tomcat.id}"]
  }
}

resource "azurerm_public_ip" "stage-tomcat-ansible" {
  count                        = 2
  name                         = "StageTomcatPublicIPForAnsible${count.index}"
  location                     = "${azurerm_resource_group.stage-tomcat.location}"
  resource_group_name          = "${azurerm_resource_group.stage-tomcat.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "stage-tomcat-ansible" {
  count               = 2
  name                = "stage-tomcat-ansible-nic${count.index}"
  location            = "${azurerm_resource_group.stage-tomcat.location}"
  resource_group_name = "${azurerm_resource_group.stage-tomcat.name}"

  ip_configuration {
    name                          = "StageTomcatAnsiblePIPConfiguration"
    subnet_id                     = "${azurerm_subnet.stage-tomcat-ansible.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.stage-tomcat-ansible.*.id, count.index)}"
  }
}


#-------------------------------------------------------
# Creating Storage
#-------------------------------------------------------

resource "azurerm_managed_disk" "stage-tomcat" {
  count                = 2
  name                 = "stage-tomcat-datadisk_${count.index}"
  location             = "${azurerm_resource_group.stage-tomcat.location}"
  resource_group_name  = "${azurerm_resource_group.stage-tomcat.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"
}

#-------------------------------------------------------
# Creating Compute
#-------------------------------------------------------

resource "azurerm_availability_set" "stage-tomcat-as" {
  name                         = "stage-tomcat-as"
  location                     = "${azurerm_resource_group.stage-tomcat.location}"
  resource_group_name          = "${azurerm_resource_group.stage-tomcat.name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

resource "azurerm_virtual_machine" "stage-tomcat" {
  count                 = 2
  name                  = "stage-tomcat-vm${count.index}"
  location              = "${azurerm_resource_group.stage-tomcat.location}"
  availability_set_id   = "${azurerm_availability_set.stage-tomcat-as.id}"
  resource_group_name   = "${azurerm_resource_group.stage-tomcat.name}"
  network_interface_ids = ["${element(azurerm_network_interface.stage-tomcat.*.id, count.index)}","${element(azurerm_network_interface.stage-tomcat-ansible.*.id, count.index)}"]
  vm_size               = "Standard_DS1_v2"

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
    name              = "stage-tomcat-osdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  # Optional data disks
  storage_data_disk {
    name              = "stage-tomcat-datadisk${count.index}"
    managed_disk_type = "Premium_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "1023"
  }

  storage_data_disk {
    name            = "${element(azurerm_managed_disk.stage-tomcat.*.name, count.index)}"
    managed_disk_id = "${element(azurerm_managed_disk.stage-tomcat.*.id, count.index)}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "${element(azurerm_managed_disk.stage-tomcat.*.disk_size_gb, count.index)}"
  }

    os_profile {
        computer_name  = "staging-tomcat"
        admin_username = "kyoheim"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/kyoheim/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCeOVMQjTiGRdPQ3s5aBEZc6NSSsC/9Q1g/7X266bJgzOMAOlqdiCwj7Mv4baN2eaZO9DDHrLVS8WQIvHti2W6SgU4cCCiQLI8FNkFwgeEtIj8Ul8IcreMpsNuQsZbs0jItxPROe6mOWpp5n2jmlFS6UgC8uBrMwx80N0w5LaZhIJb8O2kAZZAa31jXyLvX12JHMbleCx2AQ6a0MQBnL3eBrUWf2JNY9OwcuX2PDD/1aA/lmHfrasdtkMEKPaRCrXBog/GzvhwhTtxTosNVW6RYObfoHjmk5BZwACszlMrHk1BkHt6KGaERdP2r5mwiBVvsIfzyNOdm53xS9ExQInCR"
        }
    }
  tags {
    environment = "staging"
  }
}