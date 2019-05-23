data "azurerm_subnet" "jumpbox_subnet" {
  name                 = "${var.sa_jumpbox_subnetname}"
  resource_group_name  = "${var.pcf_vnet_resourcegroup}"
  virtual_network_name = "${data.azurerm_virtual_network.pcf_virtual_network.name}"
}
