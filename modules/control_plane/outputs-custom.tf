output "plane_uaa_lb_name" {
  value = "${azurerm_lb.plane-uaa.name}"
}

output "plane_uaa_credhub_name" {
  value = "${azurerm_lb.plane-credhub.name}"
}
