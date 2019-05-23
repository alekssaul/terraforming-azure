# Storage containers to be used as CF Blobstore

resource random_string "cf_storage_account_name" {
  length  = 20
  special = false
  upper   = false
}

resource "azurerm_storage_account" "cf_storage_account" {
  name                      = "${random_string.cf_storage_account_name.result}"
  resource_group_name       = "${var.resource_group_name}"
  location                  = "${var.location}"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true

  network_rules {
    virtual_network_subnet_ids = ["${data.azurerm_subnet.pas_subnet.id}"]
  }

  network_rules {
    virtual_network_subnet_ids = "${compact(
      "${var.sa_jumpbox_subnetid == "" ? "" : "data.azurerm_subnet.pas_subnet.id" }",
      "${var.sa_jumpbox_subnetid == "" ? "" : var.sa_jumpbox_subnetid }"
    )}"
  }

  tags = "${merge(map(
    "environment", var.env_name,
     "account_for", "cloud-foundry-blobstore"),
     var.azure_resource_tags
    )}"
}

resource "azurerm_storage_container" "cf_buildpacks_storage_container" {
  name                  = "${var.cf_buildpacks_storage_container_name}"
  depends_on            = ["azurerm_storage_account.cf_storage_account"]
  resource_group_name   = "${var.resource_group_name}"
  storage_account_name  = "${azurerm_storage_account.cf_storage_account.name}"
  container_access_type = "private"
}

resource "azurerm_storage_container" "cf_packages_storage_container" {
  name                  = "${var.cf_packages_storage_container_name}"
  depends_on            = ["azurerm_storage_account.cf_storage_account"]
  resource_group_name   = "${var.resource_group_name}"
  storage_account_name  = "${azurerm_storage_account.cf_storage_account.name}"
  container_access_type = "private"
}

resource "azurerm_storage_container" "cf_droplets_storage_container" {
  name                  = "${var.cf_droplets_storage_container_name}"
  depends_on            = ["azurerm_storage_account.cf_storage_account"]
  resource_group_name   = "${var.resource_group_name}"
  storage_account_name  = "${azurerm_storage_account.cf_storage_account.name}"
  container_access_type = "private"
}

resource "azurerm_storage_container" "cf_resources_storage_container" {
  name                  = "${var.cf_resources_storage_container_name}"
  depends_on            = ["azurerm_storage_account.cf_storage_account"]
  resource_group_name   = "${var.resource_group_name}"
  storage_account_name  = "${azurerm_storage_account.cf_storage_account.name}"
  container_access_type = "private"
}
