## M15-A-VM SCALE SET
resource "azurerm_virtual_network" "lab15a" {
  name                = local.lab15a_name_with_postfix
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
}

resource "azurerm_subnet" "lab15a" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.group.name
  virtual_network_name = azurerm_virtual_network.lab15a.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "lab15a" {
  name                = local.lab15a_name_with_postfix
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  allocation_method   = "Static"
  domain_name_label   = local.lab15a_name_with_postfix
}

resource "azurerm_lb" "lab15a" {
  name                = local.lab15a_name_with_postfix
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name

  frontend_ip_configuration {
    name                 = local.lab15a_name_with_postfix}
    public_ip_address_id = azurerm_public_ip.lab15a.id
  }
}

resource "azurerm_lb_backend_address_pool" "lab15a" {
  resource_group_name = azurerm_resource_group.group.name
  loadbalancer_id     = azurerm_lb.lab15a.id
  name                = local.lab15a_name_with_postfix
}

resource "azurerm_lb_nat_pool" "lab15a" {
  resource_group_name            = azurerm_resource_group.group.name
  name                           = "ssh"
  loadbalancer_id                = azurerm_lb.example.id
  protocol                       = "Tcp"
  frontend_port_start            = 50000
  frontend_port_end              = 50119
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
}

resource "azurerm_lb_probe" "example" {
  resource_group_name = azurerm_resource_group.group.name
  loadbalancer_id     = azurerm_lb.example.id
  name                = "http-probe"
  protocol            = "Http"
  request_path        = "/health"
  port                = 8080
}

resource "azurerm_virtual_machine_scale_set" "example" {
  name                = "mytestscaleset-1"
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name

  # automatic rolling upgrade
  automatic_os_upgrade = true
  upgrade_policy_mode  = "Rolling"

  rolling_upgrade_policy {
    max_batch_instance_percent              = 20
    max_unhealthy_instance_percent          = 20
    max_unhealthy_upgraded_instance_percent = 5
    pause_time_between_batches              = "PT0S"
  }

  # required when using rolling upgrade policy
  health_probe_id = azurerm_lb_probe.example.id

  sku {
    name     = "Standard_F2"
    tier     = "Standard"
    capacity = 2
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
  }

  os_profile {
    computer_name_prefix = "testvm"
    admin_username       = "myadmin"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/myadmin/.ssh/authorized_keys"
      key_data = file("~/.ssh/demo_key.pub")
    }
  }

  network_profile {
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "TestIPConfiguration"
      primary                                = true
      subnet_id                              = azurerm_subnet.example.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
      load_balancer_inbound_nat_rules_ids    = [azurerm_lb_nat_pool.lbnatpool.id]
    }
  }

  tags = {
    environment = "staging"
  }
}