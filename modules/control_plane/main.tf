locals {
  name_prefix   = "${var.env_name}-plane"
  web_ports     = [80, 443, 2222]
  uaa_ports     = [8443]
  credhub_ports = [8844]
}

# Load Balancers

# resource "azurerm_public_ip" "plane" {
#   resource_group_name = "${var.resource_group_name}"
#   name                = "${local.name_prefix}-ip"
#   location            = "${var.location}"
#   allocation_method   = "Static"
# }

resource "azurerm_lb" "plane" {
  resource_group_name = "${var.resource_group_name}"
  name                = "${var.env_name}-lb"
  location            = "${var.location}"

  frontend_ip_configuration {
    name                          = "${local.name_prefix}-ip"
    private_ip_address            = "${var.cp_lb_ipaddress}"
    private_ip_address_allocation = "Static"
    subnet_id                     = "${var.pcf_infra_subnet_id}"
  }
}

resource "azurerm_lb" "plane-uaa" {
  resource_group_name = "${var.resource_group_name}"
  name                = "${var.env_name}-uaa-lb"
  location            = "${var.location}"

  frontend_ip_configuration {
    name                          = "${local.name_prefix}-uaa-ip"
    private_ip_address            = "${var.cp_uaa_lb_ipaddress}"
    private_ip_address_allocation = "Static"
    subnet_id                     = "${var.pcf_infra_subnet_id}"
  }
}

resource "azurerm_lb" "plane-credhub" {
  resource_group_name = "${var.resource_group_name}"
  name                = "${var.env_name}-credhub-lb"
  location            = "${var.location}"

  frontend_ip_configuration {
    name                          = "${local.name_prefix}-credhub-ip"
    private_ip_address            = "${var.cp_credhub_lb_ipaddress}"
    private_ip_address_allocation = "Static"
    subnet_id                     = "${var.pcf_infra_subnet_id}"
  }
}

resource "azurerm_lb_backend_address_pool" "plane" {
  resource_group_name = "${var.resource_group_name}"
  name                = "${local.name_prefix}-pool"
  loadbalancer_id     = "${azurerm_lb.plane.id}"
}

resource "azurerm_lb_backend_address_pool" "plane-uaa" {
  resource_group_name = "${var.resource_group_name}"
  name                = "${local.name_prefix}-uaa-pool"
  loadbalancer_id     = "${azurerm_lb.plane-uaa.id}"
}

resource "azurerm_lb_backend_address_pool" "plane-credhub" {
  resource_group_name = "${var.resource_group_name}"
  name                = "${local.name_prefix}-credhub-pool"
  loadbalancer_id     = "${azurerm_lb.plane-credhub.id}"
}

resource "azurerm_lb_probe" "plane" {
  resource_group_name = "${var.resource_group_name}"
  count               = "${length(local.web_ports)}"
  name                = "${local.name_prefix}-${element(local.web_ports, count.index)}-probe"

  port     = "${element(local.web_ports, count.index)}"
  protocol = "Tcp"

  loadbalancer_id     = "${azurerm_lb.plane.id}"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_probe" "plane-uaa" {
  resource_group_name = "${var.resource_group_name}"
  count               = "${length(local.uaa_ports)}"
  name                = "${local.name_prefix}-uaa-${element(local.uaa_ports, count.index)}-probe"

  port     = "${element(local.uaa_ports, count.index)}"
  protocol = "Tcp"

  loadbalancer_id     = "${azurerm_lb.plane-uaa.id}"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_probe" "plane-credhub" {
  resource_group_name = "${var.resource_group_name}"
  count               = "${length(local.credhub_ports)}"
  name                = "${local.name_prefix}-credhub-${element(local.credhub_ports, count.index)}-probe"

  port     = "${element(local.credhub_ports, count.index)}"
  protocol = "Tcp"

  loadbalancer_id     = "${azurerm_lb.plane-credhub.id}"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "plane" {
  resource_group_name = "${var.resource_group_name}"
  count               = "${length(local.web_ports)}"
  name                = "${local.name_prefix}-${element(local.web_ports, count.index)}"

  protocol                       = "Tcp"
  loadbalancer_id                = "${azurerm_lb.plane.id}"
  frontend_port                  = "${element(local.web_ports, count.index)}"
  backend_port                   = "${element(local.web_ports, count.index)}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.plane.id}"
  frontend_ip_configuration_name = "${local.name_prefix}-ip"
  probe_id                       = "${element(azurerm_lb_probe.plane.*.id, count.index)}"
}

resource "azurerm_lb_rule" "plane-uaa" {
  resource_group_name = "${var.resource_group_name}"
  count               = "${length(local.uaa_ports)}"
  name                = "${local.name_prefix}-uaa-${element(local.uaa_ports, count.index)}"

  protocol                       = "Tcp"
  loadbalancer_id                = "${azurerm_lb.plane-uaa.id}"
  frontend_port                  = "${element(local.uaa_ports, count.index)}"
  backend_port                   = "${element(local.uaa_ports, count.index)}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.plane-uaa.id}"
  frontend_ip_configuration_name = "${local.name_prefix}-uaa-ip"
  probe_id                       = "${element(azurerm_lb_probe.plane-uaa.*.id, count.index)}"
}

resource "azurerm_lb_rule" "plane-credhub" {
  resource_group_name = "${var.resource_group_name}"
  count               = "${length(local.credhub_ports)}"
  name                = "${local.name_prefix}-credhub-${element(local.uaa_ports, count.index)}"

  protocol                       = "Tcp"
  loadbalancer_id                = "${azurerm_lb.plane-credhub.id}"
  frontend_port                  = "${element(local.uaa_ports, count.index)}"
  backend_port                   = "${element(local.uaa_ports, count.index)}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.plane-credhub.id}"
  frontend_ip_configuration_name = "${local.name_prefix}-credhub-ip"
  probe_id                       = "${element(azurerm_lb_probe.plane-credhub.*.id, count.index)}"
}

# Firewall

resource "azurerm_network_security_group" "plane" {
  name                = "${local.name_prefix}-security-group"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_network_security_rule" "plane" {
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.plane.name}"

  name                       = "${local.name_prefix}-security-group-rule"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_ranges    = "${local.web_ports}"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "plane-uaa" {
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.plane.name}"

  name                       = "${local.name_prefix}-security-group-uaa-rule"
  priority                   = 101
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_ranges    = "${local.uaa_ports}"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "plane-credhub" {
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.plane.name}"

  name                       = "${local.name_prefix}-security-group-credhub-rule"
  priority                   = 102
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_ranges    = "${local.credhub_ports}"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}

# Network

data "azurerm_subnet" "plane" {
  name                 = "${var.pcf_infrastructure_subnet_name}"
  resource_group_name  = "${var.pcf_vnet_resourcegroup}"
  virtual_network_name = "${var.network_name}"
}

# Database

resource "azurerm_postgresql_server" "plane" {
  name                = "${local.name_prefix}-postgres"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.location}"

  sku {
    name     = "B_Gen5_2"
    capacity = 2
    tier     = "Basic"
    family   = "Gen5"
  }

  storage_profile {
    storage_mb            = 10240
    backup_retention_days = 7
    geo_redundant_backup  = "Disabled"
  }

  administrator_login          = "${var.postgres_username}"
  administrator_login_password = "${random_string.postgres_password.result}"
  version                      = "9.6"
  ssl_enforcement              = "Enabled"

  count = "${var.external_db ? 1 : 0}"
}

resource "azurerm_postgresql_firewall_rule" "plane" {
  name                = "${local.name_prefix}-postgres-firewall"
  resource_group_name = "${var.resource_group_name}"
  server_name         = "${element(azurerm_postgresql_server.plane.*.name, 0)}"

  # Note, these only refer to internal AZURE IPs and not external
  # access from anywhere. Please don't change them unless you know
  # what you are doing. See terraform docs for details

  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
  count            = "${var.external_db ? 1 : 0}"
}

resource "azurerm_postgresql_database" "atc" {
  resource_group_name = "${var.resource_group_name}"
  name                = "atc"

  server_name = "${azurerm_postgresql_server.plane.name}"
  charset     = "UTF8"
  collation   = "English_United States.1252"

  count = "${var.external_db ? 1 : 0}"
}

resource "azurerm_postgresql_database" "credhub" {
  resource_group_name = "${var.resource_group_name}"
  name                = "credhub"

  server_name = "${azurerm_postgresql_server.plane.name}"
  charset     = "UTF8"
  collation   = "English_United States.1252"

  depends_on = ["azurerm_postgresql_database.atc"]
  count      = "${var.external_db ? 1 : 0}"
}

resource "azurerm_postgresql_database" "uaa" {
  resource_group_name = "${var.resource_group_name}"
  name                = "uaa"

  server_name = "${azurerm_postgresql_server.plane.name}"
  charset     = "UTF8"
  collation   = "English_United States.1252"

  depends_on = ["azurerm_postgresql_database.credhub"]
  count      = "${var.external_db ? 1 : 0}"
}

resource "random_string" "postgres_password" {
  length  = 16
  special = false
}
