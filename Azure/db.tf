
resource "azurerm_subnet" "private-subnet" {
  name                 = "my-private-subnet"
  resource_group_name  = "tech501"
  virtual_network_name = azurerm_virtual_network.zainab-vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Define a new Network Security Group (NSG) for DB VM
resource "azurerm_network_security_group" "db-nsg" {
  name                = "db-nsg"
  location            = "UK South"
  resource_group_name = "tech501"
}

# Inbound SSH Rule for DB VM (Port 22)
resource "azurerm_network_security_rule" "db_ssh_rule" {
    resource_group_name = "tech501"
  name                        = "Allow-SSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.db-nsg.name
}

# Inbound MongoDB Rule for DB VM (Port 27017)
resource "azurerm_network_security_rule" "db_mongodb_rule" {
    resource_group_name = "tech501"
  name                        = "Allow-MongoDB"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "27017"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.db-nsg.name
}

# Associate NSG with Private Subnet (for DB VM)
resource "azurerm_subnet_network_security_group_association" "nsg_association_db" {
  subnet_id                 = azurerm_subnet.private-subnet.id
  network_security_group_id = azurerm_network_security_group.db-nsg.id
}

# Define Network Interface for DB VM in Private Subnet (no Public IP)
resource "azurerm_network_interface" "db-nic" {
  name                = "zainab-db-nic"
  location            = "UK South"
  resource_group_name = "tech501"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private-subnet.id
    private_ip_address_allocation = "Dynamic"
    # No public IP for DB VM
  }
}

# Define Database VM in Private Subnet
resource "azurerm_virtual_machine" "tech501-zainab-db-vm" {
  name                = "tech501-zainab-db-vm"
  resource_group_name = "tech501"
  location            = "UK South"
  vm_size             = "Standard_B1s"

  # Network Interface association
  network_interface_ids = [azurerm_network_interface.db-nic.id]

  os_profile {
    computer_name  = "tech501-zainab-db-vm"
    admin_username = "adminuser"
    custom_data    = base64encode("#!/bin/bash\napt-get update && apt-get install -y mongodb\nsystemctl start mongodb")  # Example script to install MongoDB
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/adminuser/.ssh/authorized_keys"
      key_data = file("~/.ssh/zainab-test-ssh-2.pub")
    }
  }

  # OS Disk configuration
  storage_os_disk {
    name              = "zainab-db-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  # Image reference (your custom image for DB)
   storage_image_reference {
    id = "/subscriptions/cd36dfff-6e85-4164-b64e-b4078a773259/resourceGroups/tech501/providers/Microsoft.Compute/images/tech501-zainab-sparta-db-ready-to-run-img"
  }
  # Tags
  tags = {
    environment = "dev"
  }


}