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
  sa_jumpbox_subnetid               = "${var.sa_jumpbox_subnetid}"
}

module "ops_manager" {
  source = "../modules/ops_manager"

  env_name = "${var.env_name}"
  location = "${var.location}"

  vm_count               = "${var.ops_manager_vm ? 1 : 0}"
  ops_manager_image_uri  = "${var.ops_manager_image_uri}"
  ops_manager_vm_size    = "${var.ops_manager_vm_size}"
  ops_manager_private_ip = "${var.ops_manager_private_ip}"

  optional_ops_manager_image_uri = "${var.optional_ops_manager_image_uri}"

  resource_group_name = "${module.infra.resource_group_name}"
  security_group_id   = "${module.infra.security_group_id}"
  subnet_id           = "${module.infra.infrastructure_subnet_id}"
  azure_resource_tags = "${var.azure_resource_tags}"
  sa_jumpbox_subnetid = "${var.sa_jumpbox_subnetid}"
}

module "control_plane" {
  source = "../modules/control_plane"

  resource_group_name = "${module.infra.resource_group_name}"
  env_name            = "${var.env_name}"
  cidr                = "${var.plane_cidr}"
  network_name        = "${module.infra.network_name}"

  postgres_username = "${var.postgres_username}"

  location                       = "${var.location}"
  external_db                    = "${var.external_db}"
  cp_lb_ipaddress                = "${var.cp_lb_ipaddress}"
  cp_credhub_lb_ipaddress        = "${var.cp_credhub_lb_ipaddress}"
  cp_uaa_lb_ipaddress            = "${var.cp_uaa_lb_ipaddress}"
  pcf_infra_subnet_id            = "${module.infra.infrastructure_subnet_id}"
  pcf_infrastructure_subnet_name = "${var.pcf_infrastructure_subnet_name}"
  pcf_vnet_resourcegroup         = "${var.pcf_vnet_resourcegroup}"
}
