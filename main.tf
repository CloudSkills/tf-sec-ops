# Terraform
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.40.0"
    }
  }
}

#Azure provider
provider "azurerm" {
  features {}
}

#create resource group
resource "azurerm_resource_group" "rg" {
  name     = "rg-webserver-cs"
  location = "westus2"
}

#Create virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-webserver-${azurerm_resource_group.rg.location}-001"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "snet-webserver-${azurerm_resource_group.rg.location}-001"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

#Create NSG
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-rdpallow-001"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "RDP-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

#NSG and Subnet Association
resource "azurerm_subnet_network_security_group_association" "nsg_sub_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

module "server" {
  source = "./modules/terraform-azure-server"

  subnet_id = azurerm_subnet.subnet.id
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location

  servername = "server1"
  vm_size = "Standard_B2s"
  admin_username = "terraadmin"
  admin_password = "P@ssw0rdP@ssw0rd"
  os = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

}
