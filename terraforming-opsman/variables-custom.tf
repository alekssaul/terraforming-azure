/* 
This file contains customer variables for a particular customer.
It's been seperated from variables.tf in order to keep it easier to manage upstream changes to variables file
*/

variable "pcf_vnet_name" {
  type = "string"
}

variable "pcf_infrastructure_subnet_name" {
  type = "string"
}

variable "pcf_vnet_resourcegroup" {
  type = "string"
}

variable "azure_resource_tags" {
  type        = "map"
  description = "Tags that apply to all the Azure Resources"
  default     = {}
}

variable "sa_jumpbox_subnetid" {
  type        = "string"
  description = "Subnet ID of VM executing Terraform. Setting this to a variable enables StorageAccount Network ACLs"
  default     = ""
}
