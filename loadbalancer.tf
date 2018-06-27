resource "google_compute_target_pool" "webserver_pool" {
  name          = "webserver-pool"
  instances     = ["${google_compute_instance.webservers.*.self_link}"]
  health_checks = ["${google_compute_http_health_check.http_check.name}"]
}

resource "google_compute_forwarding_rule" "http_forward" {
  name       = "http-forward"
  target     = "${google_compute_target_pool.webserver_pool.self_link}"
  port_range = "80"
  ip_address = "${google_compute_address.ext_ip.address}"
}

resource "google_compute_address" "ext_ip" {
  name = "ext-ip"
}

resource "google_compute_http_health_check" "http_check" {
  name               = "http-check"
  timeout_sec        = 1
  check_interval_sec = 1
}
