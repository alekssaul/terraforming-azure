provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
  environment     = "${var.cloud_name}"

  version = "~> 1.22"
}

terraform {
  required_version = "< 0.12.0"
}

module "infra" {
  source = "../modules/infra"

  env_name                          = "${var.env_name}"
  location                          = "${var.location}"
  pcf_infrastructure_subnet         = "${var.pcf_infrastructure_subnet}"
  pcf_virtual_network_address_space = "${var.pcf_virtual_network_address_space}"
  pcf_vnet_name                     = "${var.pcf_vnet_name}"
  pcf_vnet_resourcegroup            = "${var.pcf_vnet_resourcegroup}"
  pcf_infrastructure_subnet_name    = "${var.pcf_infrastructure_subnet_name}"
  azure_resource_tags               = "${var.azure_resource_tags}"
}
