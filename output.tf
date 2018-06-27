output "ext_url" {
  value = "http://${google_compute_forwarding_rule.http_forward.ip_address}"
}

resource "local_file" "inventory" {
  content  = "${join("\n", google_compute_instance.webservers.*.network_interface.0.address)}"
  filename = "inventory.cfg"
}
