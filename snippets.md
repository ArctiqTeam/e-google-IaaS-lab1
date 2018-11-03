## Snippet 1
```
provider "google" {
  project = "ivory-program-207902"   # Needs to be your value.
  region  = "us-east1"               # This value can be left as is.
}
```
&nbsp;
&nbsp;
&nbsp;
## Snippet 2
```
resource "google_compute_instance" "webserver" {
  name         = "webserver"
  machine_type = "n1-standard-1"
  zone         = "us-east1-b"

  boot_disk {
    initialize_params {
      image = "centos-7"
      size  = "10"
      type  = "pd-ssd"
    }
  }

  network_interface {
    network = "default"
  }
}
```
&nbsp;
&nbsp;
&nbsp;
## Snippet 3
```
resource "google_compute_firewall" "http" {
  name    = "http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}
```
&nbsp;
&nbsp;
&nbsp;
## Snippet 4
```
resource "google_compute_instance" "webserver" {
  name         = "webserver"
  machine_type = "n1-standard-1"
  zone         = "us-east1-b"

  tags = ["http-server"]

  boot_disk {
    initialize_params {
      image = "centos-7"
      size  = "10"
      type  = "pd-ssd"
    }
  }

  network_interface {
    network = "default"

    access_config {}
  }
}
```
&nbsp;
&nbsp;
&nbsp;
## Snippet 5
```
resource "google_compute_instance" "webserver" {
  name         = "webserver"
  machine_type = "n1-standard-1"
  zone         = "us-east1-b"
  tags         = ["http-server"]

  boot_disk {
    initialize_params {
      image = "centos-7"
      size  = "10"
      type  = "pd-ssd"
    }
  }

  network_interface {
    network = "default"

    access_config {}
  }

  metadata_startup_script = <<SCRIPT
yum -y install httpd php
service httpd start
echo "<html><head><link rel="stylesheet" href="http://s.gcp.how/demo.css"></head><body><div>Hostname: $HOSTNAME<br><?php echo date('D M j G:i:s T Y'); ?></div></body></html>" > /var/www/html/index.php
SCRIPT

}
```
&nbsp;
&nbsp;
&nbsp;
## Snippet 6
```
resource "google_compute_instance" "webservers" {
  count        = 3
  name         = "webserver-${count.index + 1}"
  machine_type = "n1-standard-1"
  zone         = "us-east1-b"
  tags         = ["http-server"]

  boot_disk {
    initialize_params {
      image = "centos-7"
      size  = "10"
      type  = "pd-ssd"
    }
  }

  network_interface {
    network = "default"

    access_config {}
  }

  metadata_startup_script = <<SCRIPT
yum -y install httpd php
service httpd start
echo "<html><head><link rel="stylesheet" href="http://s.gcp.how/demo.css"></head><body><div>Hostname: $HOSTNAME<br><?php echo date('D M j G:i:s T Y'); ?></div></body></html>" > /var/www/html/index.php
SCRIPT

}
```
&nbsp;
&nbsp;
&nbsp;
## Snippet 7
```
resource "google_compute_target_pool" "webserver_pool" {
  name      = "webserver-pool"
  instances = ["${google_compute_instance.webservers.*.self_link}"]
}

resource "google_compute_forwarding_rule" "http_forward" {
  name       = "http-forward"
  target     = "${google_compute_target_pool.webserver_pool.self_link}"
  port_range = "80"
}
```
&nbsp;
&nbsp;
&nbsp;
## Snippet 8
```
output "ext_url" {
  value = "http://${google_compute_forwarding_rule.http_forward.ip_address}"
}
```
&nbsp;
&nbsp;
&nbsp;
## Snippet 9
```
resource "google_compute_target_pool" "webserver_pool" {
  name      = "webserver-pool"
  instances = ["${google_compute_instance.webservers.*.self_link}"]
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
```
&nbsp;
&nbsp;
&nbsp;
## Snippet 10
```
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
```
&nbsp;
&nbsp;
&nbsp;
## Snippet 11
```
variable "project" {
  default = "ivory-program-207902"
}

variable "region" {
  default = "us-east1"
}

variable "zones" {
  default = ["us-east1-b", "us-east1-d", "us-east1-c"]
}

variable "server_count" {
  description = "How many do we build, boss?"
}
```
&nbsp;
&nbsp;
&nbsp;
## Snippet 12
```
provider "google" {
  project = "${var.project}"
  region  = "${var.region}"
}
```
&nbsp;
&nbsp;
&nbsp;
## Snippet 13
```
zone = "${element(var.zones, count.index)}"
```
&nbsp;
&nbsp;
&nbsp;
## Snippet 14
```
count = "${var.server_count}"
```
