terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Variables
variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
}

variable "node_vm_size" {
  description = "VM size for worker nodes"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "azure_location" {
  description = "Azure region"
  type        = string
}

variable "resource_group" {
  description = "Resource group name"
  type        = string
}

variable "private_subnet" {
  description = "Private subnet ID"
  type        = string
}

variable "public_subnet" {
  description = "Public subnet ID"
  type        = string
}

variable "acr_name" {
  description = "Azure Container Registry name"
  type        = string
}

variable "enable_public_access" {
  description = "Enable public access to the cluster"
  type        = bool
  default     = true
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.azure_location
  resource_group_name = var.resource_group
  dns_prefix          = var.cluster_name
  kubernetes_version  = "1.27.7"

  default_node_pool {
    name                = "nodepool1"
    node_count          = var.node_count
    vm_size             = var.node_vm_size
    os_disk_size_gb     = 128
    max_pods            = 250
    vnet_subnet_id      = var.private_subnet
    zones               = ["1", "2", "3"]
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_plugin_mode = "overlay"
    service_cidr       = "10.0.0.0/16"
    dns_service_ip     = "10.0.0.10"
    pod_cidr           = "10.244.0.0/16"
    network_data_plane = "azure"
    ip_versions        = ["IPv4"]
  }

  tags = var.common_tags
}

# AKS ACR Integration
resource "azurerm_role_assignment" "aks_acr" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name            = "AcrPull"
  scope                           = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group}/providers/Microsoft.ContainerRegistry/registries/${var.acr_name}"
  skip_service_principal_aad_check = true
}

# Get current Azure configuration
data "azurerm_client_config" "current" {}

# Outputs
output "cluster_endpoint" {
  description = "Endpoint for Kubernetes control plane"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.host
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_credentials" {
  description = "Kubernetes cluster credentials"
  value = {
    client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate)
  }
  sensitive = true
} 