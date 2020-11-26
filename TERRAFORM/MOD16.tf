## M16-AKS
resource "azurerm_kubernetes_cluster" "lab16" {
  name                = local.lab16_name_with_postfix
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  dns_prefix          = local.lab16_name

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  addon_profile {
    aci_connector_linux {
      enabled = false
    }

    azure_policy {
      enabled = false
    }

    http_application_routing {
      enabled = false
    }

    kube_dashboard {
      enabled = true
    }

    oms_agent {
      enabled = false
    }
  }
}