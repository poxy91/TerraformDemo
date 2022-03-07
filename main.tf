# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }

  required_version = ">= 0.12"
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

resource "azurerm_resource_group" "henrikinrg" {
  name     = var.resource_group_name
  location = var.resource_group_location
  tags = {
    Environment = "Terraform Getting Started"
    Team        = "DevOps"
  }

}
#create storage account
resource "azurerm_storage_account" "storageaccount" {
  name                = var.storage_account_name
  resource_group_name = azurerm_resource_group.henrikinrg.name

  location                 = var.resource_group_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
#create storage container
resource "azurerm_storage_container" "example" {
  name                  = "blobcontainer"
  storage_account_name  = azurerm_storage_account.storageaccount.name
  container_access_type = "private"
}



# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = var.resource_group_location
    resource_group_name = azurerm_resource_group.henrikinrg.name

    tags = {
        environment = "Terraform Demo"
    }
}

  # Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = azurerm_resource_group.henrikinrg.name
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
    address_prefixes       = ["10.0.1.0/24"]
  
  
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = var.resource_group_location
    resource_group_name          = azurerm_resource_group.henrikinrg.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = var.resource_group_location
    resource_group_name = azurerm_resource_group.henrikinrg.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    #open HTTP for testing ip-adress to nginx or appache is working
security_rule {
        name                       = "HTTP"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "TCP"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }


    tags = {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
    name                      = "myNIC"
    location                  = var.resource_group_location
    resource_group_name       = azurerm_resource_group.henrikinrg.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.myterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
    network_interface_id      = azurerm_network_interface.myterraformnic.id
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id

}

resource "azurerm_virtual_machine" "vm" {

  name                  = "vm"
  location              = var.resource_group_location
  resource_group_name   = azurerm_resource_group.henrikinrg.name
  network_interface_ids = [azurerm_network_interface.myterraformnic.id]
  vm_size               = "Standard_D1_v2"


  storage_image_reference {

    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"

  }


  storage_os_disk {

    name              = "osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"

  }


  os_profile {

    computer_name  = "hostname"
    admin_username = var.admin_username
    admin_password = var.admin_password

  }

  os_profile_linux_config {

    disable_password_authentication = false

  }

}


resource "azurerm_virtual_machine_extension" "vme" {

  virtual_machine_id         = azurerm_virtual_machine.vm.id
  name                       = "vme"
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.0"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS

{

    
    "script": "${filebase64("custom_script.sh")}"
}

SETTINGS
#commandToExecute": "sudo apt-get update && apt-get install -y apache2 && echo 'hello world' > /var/www/html/index.html (instead of custom_script.sh)
}

    output "public_ip_address" {
    value = azurerm_public_ip.myterraformpublicip.*.ip_address
    }