## LAB-8-VM
resource "azurerm_virtual_network" "lab08" {
  name                = "${local.lab08_name}-vnet-${local.random_str}"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.az104.location
  resource_group_name = azurerm_resource_group.az104.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet" "lab08" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.az104.name
  virtual_network_name = azurerm_virtual_network.lab08.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "lab08bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.az104.name
  virtual_network_name = azurerm_virtual_network.lab08.name
  address_prefixes     = ["10.10.2.0/24"]
}

resource "azurerm_public_ip" "lab08" {
  name                = "${local.lab08_name}-pip-${local.random_str}"
  location            = azurerm_resource_group.az104.location
  resource_group_name = azurerm_resource_group.az104.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${local.lab08_name}-vm-${local.random_str}"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_group" "lab08" {
  name                = "${local.lab08_name}-nsg-${local.random_str}"
  location            = azurerm_resource_group.az104.location
  resource_group_name = azurerm_resource_group.az104.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_rule" "lab0801" {
  name                        = "RDP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = chomp(data.http.myip.response_body)
  destination_port_range      = "3389"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.az104.name
  network_security_group_name = azurerm_network_security_group.lab08.name
}

resource "azurerm_network_security_rule" "lab0802" {
  name                        = "HTTP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = chomp(data.http.myip.response_body)
  destination_port_range      = "80"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.az104.name
  network_security_group_name = azurerm_network_security_group.lab08.name
}

resource "azurerm_network_interface" "lab08" {
  name                = "${local.lab08_name}-nic-${local.random_str}"
  location            = azurerm_resource_group.az104.location
  resource_group_name = azurerm_resource_group.az104.name

  ip_configuration {
    name                          = "${local.lab08_name}-nic-ipconfig-${local.random_str}"
    subnet_id                     = azurerm_subnet.lab08.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab08.id
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_interface_security_group_association" "lab08" {
  network_interface_id      = azurerm_network_interface.lab08.id
  network_security_group_id = azurerm_network_security_group.lab08.id
}

resource "azurerm_windows_virtual_machine" "lab08" {
  name                  = "${local.lab08_name}-vm-${local.random_str}"
  location              = azurerm_resource_group.az104.location
  resource_group_name   = azurerm_resource_group.az104.name
  network_interface_ids = [azurerm_network_interface.lab08.id]
  size                  = local.vm_size

  os_disk {
    name                 = "${local.lab08_name}-osdisk-${local.random_str}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  computer_name  = "${local.lab08_name}-vm-${local.random_str}"
  admin_username = local.user_name
  admin_password = local.user_passowrd

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_machine_extension" "lab08script" {
  name                       = "${local.lab08_name}-script-${local.random_str}"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.lab08.id

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item 'C:\\inetpub\\wwwroot\\iisstart.htm' && powershell.exe Add-Content -Path 'C:\\inetpub\\wwwroot\\iisstart.htm' -Value $('Hello World from ' + $env:computername)"
    }
  SETTINGS

  tags = {
    environment = local.group_name
  }
}
