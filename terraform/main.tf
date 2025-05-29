terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "blaze-rg"
  location = "eastus"
}

resource "azurerm_container_registry" "acr" {
  name                = "blazeacr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "blaze-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "blaze-aks-blaze-rg-d46c26"
  kubernetes_version  = "1.31"

  default_node_pool {
    name       = "nodepool1"
    node_count = 3
    vm_size    = "Standard_D2s_v3"
    os_disk_size_gb = 128
    os_sku     = "Ubuntu"
    max_pods   = 250
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_plugin_mode = "overlay"
    network_policy     = "azure"
    load_balancer_sku  = "standard"
    service_cidr       = "10.0.0.0/16"
    dns_service_ip     = "10.0.0.10"
    pod_cidr           = "10.244.0.0/16"
    outbound_type      = "loadBalancer"
  }

  linux_profile {
    admin_username = "azureuser"
    ssh_key {
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGxvX3b5yZuluWXD1AW4IlkqiYEU7HbFxtBR2bcFa8xr6sljK3pxbeI8tWJW7NrkF3Y4ny5Ic/+El7erx1pwSd/ea2rHxavbUbcbbpTb0LLLBSwVOiwIzlye4e9/tc58WwIjxOMxJ2Ua6HX/jkwa2G2QP7qTY9xGP43MrVn7Jc7gqh32ZlX2CaQfPw5ieK8FOwxMW8Fz6SQHhm5BKqtuMjTeBOLYfu+4vk6zTsSUhRhOamltZlZZuPi793qqmzPU9fqwLJoO86ioq5XSrYIA/ZUxd8+4EfYUWbfHNlvWFNzYNuMm7t/tJGpFef7jRUNEhwpPVKu1OtwOFKWHsYrvEp"
    }
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
} 