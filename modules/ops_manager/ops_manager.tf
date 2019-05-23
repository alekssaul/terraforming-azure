# ==================== Variables

variable "env_name" {
  default = ""
}

variable "location" {
  default = ""
}

variable "vm_count" {
  default = 1
}

variable "ops_manager_private_ip" {
  default = ""
}

variable "ops_manager_image_uri" {
  default = ""
}

variable "ops_manager_vm_size" {
  default = ""
}

variable "resource_group_name" {
  default = ""
}

variable "security_group_id" {
  default = ""
}

variable "subnet_id" {
  default = ""
}

variable "dns_zone_name" {
  default = ""
}

resource random_string "ops_manager_storage_account_name" {
  length  = 20
  special = false
  upper   = false
}

variable "azure_resource_tags" {
  type        = "map"
  description = "Tags that apply to all the Azure Resources"
  default     = {}
}

# ==================== Storage

resource "azurerm_storage_account" "ops_manager_storage_account" {
  name                      = "${random_string.ops_manager_storage_account_name.result}"
  resource_group_name       = "${var.resource_group_name}"
  location                  = "${var.location}"
  account_tier              = "Premium"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true

  network_rules {
    virtual_network_subnet_ids = "${compact(
      "${var.sa_jumpbox_subnetid == "" ? "" : "var.subnet_id" }",
      "${var.sa_jumpbox_subnetid == "" ? "" : var.sa_jumpbox_subnetid }"
    )}"
  }

  tags = "${merge(map(
    "environment", var.env_name,
     "account_for", "ops-manager"),
     var.azure_resource_tags
    )}"
}

resource "azurerm_storage_container" "ops_manager_storage_container" {
  name                  = "opsmanagerimage"
  depends_on            = ["azurerm_storage_account.ops_manager_storage_account"]
  resource_group_name   = "${var.resource_group_name}"
  storage_account_name  = "${azurerm_storage_account.ops_manager_storage_account.name}"
  container_access_type = "private"
}

resource "azurerm_storage_blob" "ops_manager_image" {
  name                   = "opsman.vhd"
  resource_group_name    = "${var.resource_group_name}"
  storage_account_name   = "${azurerm_storage_account.ops_manager_storage_account.name}"
  storage_container_name = "${azurerm_storage_container.ops_manager_storage_container.name}"
  source_uri             = "${var.ops_manager_image_uri}"
  count                  = "${var.vm_count}"
}

resource "azurerm_image" "ops_manager_image" {
  name                = "ops_manager_image"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  count               = "${var.vm_count}"

  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = "${azurerm_storage_blob.ops_manager_image.url}"
    size_gb  = 150
  }
}

# ==================== VMs

resource "azurerm_network_interface" "ops_manager_nic" {
  name                      = "${var.env_name}-ops-manager-nic"
  location                  = "${var.location}"
  resource_group_name       = "${var.resource_group_name}"
  network_security_group_id = "${var.security_group_id}"
  count                     = "${var.vm_count}"

  ip_configuration {
    name                          = "${var.env_name}-ops-manager-ip-config"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.ops_manager_private_ip}"

    //public_ip_address_id          = "${azurerm_public_ip.ops_manager_public_ip.id}"
  }
}

resource "azurerm_virtual_machine" "ops_manager_vm" {
  name                          = "${var.env_name}-ops-manager-vm"
  depends_on                    = ["azurerm_network_interface.ops_manager_nic"]
  location                      = "${var.location}"
  resource_group_name           = "${var.resource_group_name}"
  network_interface_ids         = ["${azurerm_network_interface.ops_manager_nic.id}"]
  vm_size                       = "${var.ops_manager_vm_size}"
  delete_os_disk_on_termination = "true"
  count                         = "${var.vm_count}"

  storage_image_reference {
    id = "${azurerm_image.ops_manager_image.id}"
  }

  storage_os_disk {
    name              = "opsman-disk.vhd"
    caching           = "ReadWrite"
    os_type           = "linux"
    create_option     = "FromImage"
    disk_size_gb      = "150"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = "${var.env_name}-ops-manager"
    admin_username = "ubuntu"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/ubuntu/.ssh/authorized_keys"
      key_data = "${tls_private_key.ops_manager.public_key_openssh}"
    }
  }
}

resource "tls_private_key" "ops_manager" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

# ==================== OPTIONAL

variable "optional_ops_manager_image_uri" {
  default = ""
}

# ==================== Outputs
output "ops_manager_private_ip" {
  value = "${var.ops_manager_private_ip}"
}

output "ops_manager_ssh_public_key" {
  sensitive = true
  value     = "${tls_private_key.ops_manager.public_key_openssh}"
}

output "ops_manager_ssh_private_key" {
  sensitive = true
  value     = "${tls_private_key.ops_manager.private_key_pem}"
}

output "ops_manager_storage_account" {
  value = "${azurerm_storage_account.ops_manager_storage_account.name}"
}
