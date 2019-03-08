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
}

module "pas" {
  source = "../modules/pas"

  env_name = "${var.env_name}"
  location = "${var.location}"

  pas_subnet_cidr = "${var.pcf_pas_subnet}"
  pcf_infra_subnet_id ="${module.infra.infrastructure_subnet_id}"

  cf_storage_account_name              = "${var.cf_storage_account_name}"
  cf_buildpacks_storage_container_name = "${var.cf_buildpacks_storage_container_name}"
  cf_droplets_storage_container_name   = "${var.cf_droplets_storage_container_name}"
  cf_packages_storage_container_name   = "${var.cf_packages_storage_container_name}"
  cf_resources_storage_container_name  = "${var.cf_resources_storage_container_name}"

  resource_group_name                 = "${module.infra.resource_group_name}"
  network_name                        = "${module.infra.network_name}"
  bosh_deployed_vms_security_group_id = "${module.infra.bosh_deployed_vms_security_group_id}"
  pcf_services_subnet_name            = "${var.pcf_services_subnet_name}"
  pcf_pas_subnet_name = "${var.pcf_pas_subnet_name}"
  pcf_monitoring_services_subnet_name = "${var.pcf_monitoring_services_subnet_name}"
  diego-ssh_lb_ipaddress              = "${var.diego-ssh_lb_ipaddress}"
  pcf_vnet_resourcegroup            = "${var.pcf_vnet_resourcegroup}"
  tcp-ssh_lb_ipaddress              = "${var.tcp-ssh_lb_ipaddress}"
  mysql-ssh_lb_ipaddress              = "${var.mysql-ssh_lb_ipaddress}"
  web-ssh_lb_ipaddress              = "${var.web-ssh_lb_ipaddress}"
}

/*
module "certs" {
  source = "../modules/certs"

  env_name           = "${var.env_name}"
  dns_suffix         = "${var.dns_suffix}"
  ssl_ca_cert        = "${var.ssl_ca_cert}"
  ssl_ca_private_key = "${var.ssl_ca_private_key}"
}


module "isolation_segment" {
  source = "../modules/isolation_segment"

  count = "${var.isolation_segment ? 1 : 0}"

  environment = "${var.env_name}"
  location    = "${var.location}"

  ssl_cert           = "${var.iso_seg_ssl_cert}"
  ssl_private_key    = "${var.iso_seg_ssl_private_key}"
  ssl_ca_cert        = "${var.iso_seg_ssl_ca_cert}"
  ssl_ca_private_key = "${var.iso_seg_ssl_ca_private_key}"

  resource_group_name = "${module.infra.resource_group_name}"
}
*/

