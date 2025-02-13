provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
  subscription_id                 = "cd36dfff-6e85-4164-b64e-b4078a773259"
}


# Virtual Network definition
resource "azurerm_virtual_network" "zainab-vnet" {
  name                = "zainab-my-vnet"
  location            = "UK South"
  resource_group_name = "tech501"
  address_space       = ["10.0.0.0/16"]
}

# Public Subnet definition
resource "azurerm_subnet" "public-subnet" {
  name                 = "my-public-subnet"
  resource_group_name  = "tech501"
  virtual_network_name = azurerm_virtual_network.zainab-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Network Security Group (NSG)
resource "azurerm_network_security_group" "zainab-nsg" {
  name                = "zainab-nsg"
  location            = "UK South"
  resource_group_name = "tech501"
}

# Inbound SSH Rule (Port 22)
resource "azurerm_network_security_rule" "ssh_rule" {
  resource_group_name         = "tech501"
  name                        = "Allow-SSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.zainab-nsg.name
}

# Inbound HTTP Rule (Port 80)
resource "azurerm_network_security_rule" "http_rule" {
  resource_group_name         = "tech501"
  name                        = "Allow-HTTP"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3000"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.zainab-nsg.name
}

resource "azurerm_network_security_rule" "db_rule" {
  resource_group_name         = "tech501"
  name                        = "Allow-3000"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.zainab-nsg.name
}


# Associate NSG with Public Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.public-subnet.id
  network_security_group_id = azurerm_network_security_group.zainab-nsg.id
}

# Create Public IP
resource "azurerm_public_ip" "my_public_ip" {
  name                = "my-public-ip"
  location            = "UK South"
  resource_group_name = "tech501"
  allocation_method   = "Dynamic" # If you need a static IP, change this to "Static"
  sku                 = "Basic"
}

#locals {
#ssh_public_key = file("~/.ssh/zainab-test-ssh-2.pub")  # Update this path to your public key file
#}


# Network Interface definition for VM in Public Subnet
resource "azurerm_network_interface" "nic" {
  name                = "zainab-nic"
  location            = "UK South"
  resource_group_name = "tech501"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_public_ip.id
  }
}

# Virtual Machine definition in Public Subnet
resource "azurerm_virtual_machine" "my-app-vm" {
  name                = "zainab-app-vm"
  resource_group_name = "tech501"
  location            = "UK South"
  vm_size             = "Standard_B1s"

  # Network Interface association
  network_interface_ids = [azurerm_network_interface.nic.id]

  os_profile {
    computer_name  = "zainab-app-vm"
    admin_username = "adminuser"
    custom_data    = base64encode("#!/bin/bash\ncd /repo/app\nexport DB_HOST=mongodb://10.0.3.4:27017/posts\npm2 start app.js") # User data script
  }                                                                                                                             # User data script


  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/adminuser/.ssh/authorized_keys"
      key_data = file("~/.ssh/zainab-test-ssh-2.pub")
    }
  }
  # OS Disk configuration
  storage_os_disk {
    name              = "zainab-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }


  # VM Tags
  tags = {
    environment = "dev"

  }
  storage_image_reference {
    id = "/subscriptions/cd36dfff-6e85-4164-b64e-b4078a773259/resourceGroups/tech501/providers/Microsoft.Compute/images/tech501-zainab-sparta-app-ready-to-run-img"
  }

    # Ensure DB VM is created after App VM
  depends_on = [
    azurerm_virtual_machine.tech501-zainab-db-vm
  ]
}
