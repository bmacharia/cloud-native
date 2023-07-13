# ssh-keygen -t rsa -b 4096 -C "mydigitaloceankey" -f ~/.ssh/mykey
# export DIGITALOCEAN_TOKEN=xxxxxx

terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

variable "do_token" {
  type = string
}

variable "region" {
  default = "SFO3"
}


provider "digitalocean" {
  token = var.do_token
}
  


data "digitalocean_project" "playground" {
  name = "Cloud Native Microservices with Kubernetes"
}

resource "digitalocean_ssh_key" "my_ssh_key" {
  name       = "mykey"
  public_key = file("~/.ssh/mykey.pub")
}

resource "digitalocean_project_resources" "playground" {
  project   = data.digitalocean_project.playground.id
  resources = [for droplet in digitalocean_droplet.my_droplets : droplet.urn]
}
// Define a list of names for the droplets
variable "names" {
  default = [
    "rawdawg"
  ]
}

// Use a for_each loop to create a droplet for each name in the list
resource "digitalocean_droplet" "my_droplets" {
  for_each = { for name in var.names : name => name }


  image      = "ubuntu-20-04-x64"
  name       = each.value
  region     = var.region
  size       = "s-1vcpu-1gb"
  ssh_keys   = [digitalocean_ssh_key.my_ssh_key.id]
  monitoring = false
  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "sudo apt-get update",
      "sudo apt-get install -y net-tools",
    ]
  }

}

//Use a for_each loop to create a floating IP for each droplet
output "droplet_ip_addresses" {
  value = {
    for name, droplet in digitalocean_droplet.my_droplets : name => droplet.ipv4_address
  }

}
