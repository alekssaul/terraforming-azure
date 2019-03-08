# ================================= Subnets ====================================

data "azurerm_subnet" "pas_subnet" {
  name = "${var.pcf_pas_subnet_name}"

  //  depends_on                = ["${var.resource_group_name}"]
  resource_group_name  = "${var.pcf_vnet_resourcegroup}"
  virtual_network_name = "${var.network_name}"
}

resource "azurerm_subnet_network_security_group_association" "pas_subnet" {
  subnet_id                 = "${data.azurerm_subnet.pas_subnet.id}"
  network_security_group_id = "${var.bosh_deployed_vms_security_group_id}"
}

data "azurerm_subnet" "services_subnet" {
  name = "${var.pcf_services_subnet_name}"

  //  depends_on                = ["${var.resource_group_name}"]
  resource_group_name  = "${var.pcf_vnet_resourcegroup}"
  virtual_network_name = "${var.network_name}"
}

resource "azurerm_subnet_network_security_group_association" "services_subnet" {
  subnet_id                 = "${data.azurerm_subnet.services_subnet.id}"
  network_security_group_id = "${var.bosh_deployed_vms_security_group_id}"
}

data "azurerm_subnet" "monitoring_services_subnet" {
  name                 = "${var.pcf_monitoring_services_subnet_name}"
  resource_group_name  = "${var.pcf_vnet_resourcegroup}"
  virtual_network_name = "${var.network_name}"
}

resource "azurerm_subnet_network_security_group_association" "monitoring_services_subnet" {
  subnet_id                 = "${data.azurerm_subnet.monitoring_services_subnet.id}"
  network_security_group_id = "${var.bosh_deployed_vms_security_group_id}"
}
