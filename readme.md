# Terraform

## Installation

As we can not install the Terraform in a usual way on Google Cloud Shell, we will help you work around this.

As you are still in the root of your home directory.

Create a new directory called `bin`using the `mkdir bin` command.

Switch into the created directory `cd bin`.

Navigate to the download section of the Terraform website [https://www.terraform.io/downloads.html](https://www.terraform.io/downloads.html)

Under the Linux section right-click on the 64-bit link and click "Copy link address".

Return to the Shell and download the file using `wget` + paste the clipboard. It will look something like `wget https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip`

Once the file is downloaded Unzip it using the `unzip terraform_0.11.7_linux_amd64.zip` command.

Clean up the archive `rm terraform_0.11.7_linux_amd64.zip`

Check your directory and you should have a `terrafrom` file in there.

To make it executable run `chmod u+x terraform`.

Test your installation `terraform --version` should produce the currently installed version.

To make our life easy Google has already added a conditonal statement that adds the bin directory to the PATH. For this to happen we need to restart the server. In the right top corner click on the **three dots** and select **Reboot** from the menu.

## Project Directory

To keep things tidy, lets create a directory to keep our files. We recommend calling it workshop. Feel free to use the Code Editor or Shell depending on what you prefer.

## Create a Webserver

Switch to the workshop directory in the shell `cd workshop`

### Setup the "provider"

In the workshop directory create a file called **main.tf** and open it in the editor.

```
provider "google" {
  project = "ivory-program-207902"   # Needs to be your value.
  region  = "us-east1"               # This value can be left as is.
}
```

Provider block tells Terraform which provider will be used. There is a way to work with multiple providers in the same project, but it is outside the scope of this workshop.

The `project` value holds the name of the Google Cloud Platform \(GCP\) Project. Yours is visible and highlighted in yellow in the Shell. 

The `region` value is the region in which our configuration is going to be deployed.

Running Terraform configuration in the GCP Shell is a special case as we are already authenticated. Under other circumstances a JSON file created in the GCP UI is needed to be saved locally and included in the provider block using a credentials value. For example `credentials = "${file("account.json")}"`

At this point run `terraform init` to initialaze and then `terraform apply`. You should get no errors, but nothing is created at this time. Yet...

### Create a VM Instance

In the workshop directory create a file called **server.tf** and open it in the editor.

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

In the GCP Console navigate to **Compute Engine** -&gt; [**VM Instances**](https://console.cloud.google.com/compute/instances). You should see your server here. Notice that at this point it does not even have an **External IP** address. Even if it did, there is no **Firewall Rule** that would allow it to be exposed.

### Add Firewall Rule and External IP

First let us create a firewall rule. Create a file called **firewall.tf** and open it.

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

Notice the `target_tags` parameter. It hold the tags that will be affected by this rule.

Go back to the **server.tf** file. 

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

We add two lines to our configuration. The `tags = ["http-server"]` sets a mentioned earlier tag and applies the firewall rule associated with it. Note that tags parameter accepts an array. We only pass one element, but more can be passed separated by commas.

The `access_config {}` parameter tells the configuration to setup an external IP address. The address with be Ephemeral \(not static\) and replace during reboot. This will work for testing.

Run `terrafrom apply` and accept the changes.

Return to the [**VM Instances**](https://console.cloud.google.com/compute/instances) in the GCP Console. You should now see a an **External IP** assigned to the server. You can click the link and a new tab will open, but you will get an error message.

There is no actual web server running on our newly crated instance.

### Install, Configure and Start Apache HTTP Server

The easiest way to have some basic configuration done on our instance is a startup script. There a several way of acheving this, but we will look at the most basic one. The `metadata_startup_script`parameter simply accepts a string that will be ran once the server boots up.

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

It our script we are installing Apache and PHP, then starting the service. To cutomize it a bit and to be able to tell our server and if we are looking at a chached version we write a hostname and current time into a PHP page. The hostname is set during the script run and time is generated by the PHP every time the page is accessed. Note that it is important not to leave spaces in front of the new lines in the script.

Run `terrafrom apply` and accept the changes. Notice that the server will be destoied and created again. This is done because the creation on any changes to the `metadata_startup_script` force recreation of the instance. It only makes sense as a new script needs to be ran.

Return the the [**VM Instances**](https://console.cloud.google.com/compute/instances) in the GCP Console. Click on the **External IP** link. In the new tab you should see a response from your instance telling you it's hostname and current date and time.

Congratulations! You have created your first server using Terraform!

## Create a Load Balanced Web Server Pool

Let us move one to an example that may be a bit more practical and have a bit of a redundancy rolled into it. A load balance pool of servers.

### Additional Servers

As far as pools go we would need more than one server. Number three comes to mind as nice start. But how would we go about doing it? Well obviously copy and past the first one that we have made and replace the name parameter. D'oh!

Although that would be a correct choice, but it is not an optimal one. Especially considering that we may want a pool of couple of dozen servers in some cases.

Luckily Terraform support a parameter called `count` in most of it's resource blocks. This turns a resource block into a loop that creates as many instances as specified by the `count` parameter.

But what about the `name` parameter? Each instance needs a unique one. A small trick that uses the index of the current loop can be used and concatenetad with the name. Lets take a look.

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

I am sure `count = 3` did not create a lot of mystery, but what is `${count.index + 1}`? Well, there comes time in every Terraform's configuration life to... use **variables**. Variables in Terraform are always included in the `${}`. Inside the backet we are simply calling to the current index of the loop. Since our loop is zero based and we don't want our first server to have a hostname of `webserver-0` we simply add one to it.

Notice that I sneakily changed the resource block from "webserver" to "webserver**s**". Since it is now going to be a collection of servers this variable names makes more sense to me.

It's that time again... Run `terrafrom apply` and accept the changes. Switch back to the  [**VM Instances**](https://console.cloud.google.com/compute/instances) and witness the miracle. Feel free to click on the External IP link of each server to see what you get back.

### Load Balancer

In the workshop directory create a file called **loadbalancer.tf** and open it in the editor.

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

The configuration above creates the most basic load balancer.

First we define a pool of servers that will be used by passing previously created collection of webservers as an **instances** parameter. The way the collection is refered to is something to wrap your head around, but that is all I can say. You will get used to it.

Second block defines the forwarding rule. Very basic in this case, just port 80. It forwards it to the pool we just created in the block above. First we have the **type of a resource** used. Then, separated by the dot, we have the **actual varible** we assigned to the particular instance. Lastly we have **self\_link**. Another item you will get used to.

Run `terrafrom apply` and accept the changes. Navigate to **Network services** -&gt; [**Load balancing**](https://console.cloud.google.com/net-services/loadbalancing/loadBalancers/list). You should see the webserver-pool. Click on it. Here you will find the IP address assigned. Copy it and past in the new browser tab. You should hit of of the three servers we just brouhgt up. You can keep refreshing your page to see if you hit another one. If that gets tiring go to the VM Instances and shut down the serer you are currently hitting. Then refersh and another servers will respond.

### Output

Digging in the console to find the IP address of the load balancer was a bit of an annoying task. There is a better way to find out what the IP is. Terraform has a notion of Output. It displays output at the end of the run and it saves the values in the state file for later use. We will make use of the first point.

In the workshop directory create a file called **loadbalancer.tf** and open it in the editor.

```
output "ext_url" {
  value = "http://${google_compute_forwarding_rule.http_forward.ip_address}"
}
```

Output is defined by the output followed by the name that will refer to it latter and show up at the end of the execution. Value is what will be shown and recorded. In our case I added the http:// to the address as it makes it instantly clickable in the Google Cloud Shell. Very nice!

Run `terrafrom apply` and no need to accept the changes. There are none. Yet the output is shown in the end. Click on the created link to open it.

### Static IP

Not having a static external IP really puts a dent in the usability of our new creation. Let us fix this.

Return to the loadbalancer.tf file.

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

In the last block we created a resouce for our static external IP and gave it a name. That is all that it takes to create one.

At the bottom of the pervious block we attached it to the `ip_address` parameter. Pretty basic.

Notice that the IP block is after the forwarding rule block. The Terraform configurations are not procedural. The order is determined after everything \(all the files in the directory\) is loaded and dependencies calculated. That will determine the order of execution and creation. Order of files and configuration inside each does not matter.

Run `terrafrom apply` and accept the changes. Navigate to **VPC network** -&gt; [**External IP addresses**](https://console.cloud.google.com/networking/addresses/list) and inspect the newly created **ext-ip**. It should indicate **static** as it's type.

### Health Check

Currently our load balancer is working and even has an statis IP. However it is missing one important comonent - health check. It spreads the traffic amongst server, but has no idea if they are up or not. Let us fix this.

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

We added yet another block to the end of the file. It creates a heath check configuration. Although in general only the name parameter is needed for this we add timout and check interval of one second for each. The default is 5 \(I believe\) and we are just not that patient.

Notice that the health check configuration getts attached to the `webserver_pool` using `health_checks` parameter which accepts a collection, yet we are passing in just one item.

Run `terrafrom apply` and accept the changes. Navigate to **Network services** -&gt; [**Load balancing**](https://console.cloud.google.com/net-services/loadbalancing/loadBalancers/list). Click on the webserver-pool. You should see the health of all the webservers here.

## Variables

No configuration would be complete withouth setting some variables. We can put our values in the configuration like we have, but centralizing them creates a much more editable setup.

In the workshop directory create a file called **variables.tf** and open it in the editor.

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

The code above creates four variables and assigs default values to three of them. First two are very straight forward. The third one is an array. We set three different zones that we can deploy to. While the last variable does not have a default it has a description. You will see why latter.

Return to the **main.tf** file.

```
provider "google" {
  project = "${var.project}"
  region  = "${var.region}"
}
```

Replace hardcoded values with the variables. Notice the syntax for defined variables. They are prefixed with `var.`

Switch over to the **server.tf** file.

```
zone = "${element(var.zones, count.index)}"
```

Replace the zones parameter with this fancy looking one. Let me explain. This assignment will step through the zones array using the count index. Impressive, eh?!

```
count = "${var.server_count}"
```

Replace count parameter with this, fairly straight forward value.

Run `terrafrom apply` and... What is this? It's asking you how many instances you want to build. This is because we defined the variable, but did not set it. Terraform will ask you for it at runtime and provide the descripton that we set earlier.

Pick a number between 3 and 8. While sky is the limit on GCP your free tier account isn't. It has an 8 instance quota. How about a lucky number 7?

Switch back to the  [**VM Instances**](https://console.cloud.google.com/compute/instances). You should see as many servers as you have wished for. Notice them nicely spread across zones.

You may wonder how did an array of 3 zones fill more than 3 servers. It's a bit of a special feature in Terraform. When array end is reached it starts lopping from the top. This is very useful for situations like the current one.

## Conclusion

In less than 100 lines of configuration we have created a fully functional load balanced webserver configuration.

I hope that this was a fun introduction to what Terraform can do for you on GCP and how it does it.
