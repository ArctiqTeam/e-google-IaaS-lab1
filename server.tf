resource "google_compute_instance" "webservers" {
  count        = "${var.server_count}"
  name         = "webserver-${count.index + 1}"
  machine_type = "n1-standard-1"
  zone         = "${element(var.zones, count.index)}"
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
