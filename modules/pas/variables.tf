variable "env_name" {}
variable "location" {}
variable "resource_group_name" {}

variable "cf_buildpacks_storage_container_name" {}
variable "cf_droplets_storage_container_name" {}
variable "cf_packages_storage_container_name" {}
variable "cf_resources_storage_container_name" {}
variable "cf_storage_account_name" {}

variable "network_name" {}
variable "pas_subnet_cidr" {}

variable "bosh_deployed_vms_security_group_id" {}

variable "pcf_services_subnet_name" {
  type = "string"
}

variable "pcf_monitoring_services_subnet_name" {
  type = "string"
}

variable "diego-ssh_lb_ipaddress" {
  type = "string"
}

variable "web-ssh_lb_ipaddress" {
  type = "string"
}


variable "tcp-ssh_lb_ipaddress" {
  type = "string"
}


variable "mysql-ssh_lb_ipaddress" {
  type = "string"
}


variable "pcf_vnet_resourcegroup" {
  default = ""
}