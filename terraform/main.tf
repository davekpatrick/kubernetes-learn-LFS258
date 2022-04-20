#######################################################################################################################
## ----------------------##----------------------------------------------------------------------------------------- ##
## Terraform Root Module ## 
## ----------------------##
## - 
## ----------------------------------------------------------------------------------------------------------------- ##
#######################################################################################################################
#BOF
terraform {
  # Terraform version required for this module to function
  required_version = "~> 1.1"
  # ---------------------------------------------------
  # Setup providers
  # ---------------------------------------------------
  required_providers {
    #
    null = {
      source  = "registry.terraform.io/hashicorp/null"
      version = "3.1.1"
    }
    #
    local = {
      source  = "registry.terraform.io/hashicorp/local"
      version = "2.2.2"
    }
    #
    google = {
      source  = "registry.terraform.io/hashicorp/google"
      version = "4.15.0"
    }
  } #END => required_providers
  # ---------------------------------------------------
  # Setup state
  # ---------------------------------------------------
  # not required in the module code
  # ---------------------------------------------------
} #END => terraform
## ---------------------------------------------------
## provider setup and authorization
## ---------------------------------------------------
provider "google" {
  # auth for this provider 
  credentials = file(var.gcpAuthFile)
  # assign the project to execute within
  project = var.gcpProject
  # setup location
  region = var.gcpRegion
  zone   = var.gcpZone
} # END => provider
#######################################################################################################################
## ----------------------------------------------------------------------------------------------------------------- ##
## Local variable setup
## ----------------------------------------------------------------------------------------------------------------- ##
#######################################################################################################################
#
locals {
  # map of all virtual machine instances created 
  vmInstances = { for i in range(0, length(resource.google_compute_instance.vmInstance)) :
    resource.google_dns_record_set.A[i].name => { 
      externalIp = resource.google_compute_instance.vmInstance[i].network_interface[0].access_config[0].nat_ip 
      ip = resource.google_compute_instance.vmInstance[i].network_interface[0].network_ip 
      nodeType = i == 0 ? "controlPlane" : "worker"
    }
  }
  # Number of instances in existance. used by CI/CD workflow
  outputNumInstances = length(local.vmInstances)
}
#######################################################################################################################
## ----------------------------------------------------------------------------------------------------------------- ##
## Data blocks
## ----------------------------------------------------------------------------------------------------------------- ##
#######################################################################################################################
#
data "google_compute_image" "computeImage" {
  project = "ubuntu-os-cloud"
  family  = "ubuntu-2004-lts"
}
#
data "google_dns_managed_zone" "dnsZone" {
  name = var.dnsZone
}
# 
data "google_compute_network" "vpc" {
  name = var.dnsZone
} 
#######################################################################################################################
## ----------------------------------------------------------------------------------------------------------------- ##
## Resource blocks
## ----------------------------------------------------------------------------------------------------------------- ##
#######################################################################################################################
## ---------------------------------------------------
## ---------------------------------------------------
resource "google_compute_firewall" "external" {
  name          = "terraform-external"
  network       = data.google_compute_network.vpc.name
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  # testing 
  allow {
    protocol = "icmp"
  }
  # SSH connections
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  # testing/management consoles
  allow {
    protocol = "tcp"
    ports    = ["31500"]
  }
}
## ---------------------------------------------------
## ---------------------------------------------------
resource "google_compute_firewall" "internal" {
  name          = "terraform-internal"
  network       = data.google_compute_network.vpc.name
  direction     = "INGRESS"
  #
  source_ranges = [var.subnetRange]
  #
  allow {
    protocol = "all"
  }
}
## ---------------------------------------------------
## ---------------------------------------------------
resource "google_compute_subnetwork" "subnet" {
  name          = var.computeInstanceKey
  ip_cidr_range = var.subnetRange
  region        = var.gcpRegion
  network       = data.google_compute_network.vpc.id
}
## ---------------------------------------------------
## ---------------------------------------------------
resource "google_compute_address" "vmInstanceStaticIP" {
  # how many instances of this resource to create
  count = var.computeInstances
  #
  name         = format("%s%02s", var.computeInstanceKey, count.index)
  address_type = "EXTERNAL"
}

## ---------------------------------------------------
## ---------------------------------------------------
resource "google_compute_instance" "vmInstance" {
  # how many instances of this resource to create
  count = var.computeInstances
  #
  name         = format("%s%02s", var.computeInstanceKey, count.index)
  machine_type              = var.computeMachineType
  allow_stopping_for_update = true 
  #
  hostname = format("%s%02s.%s.%s", var.computeInstanceKey, count.index, var.dnsZone,  var.dnsDomain)
  # 
  tags = concat([lower(var.computeEnvironment)],
                       var.computeTags
        )
  # 
  boot_disk {
    initialize_params {
      # 
      image = data.google_compute_image.computeImage.self_link
    }
  }
  #
  network_interface {
    # use the provisioned VPC network
    network    = data.google_compute_network.vpc.name
    subnetwork = resource.google_compute_subnetwork.subnet.name
    access_config {
      # assign the provisioned static IP address
      nat_ip = google_compute_address.vmInstanceStaticIP[count.index].address
    }
  }
  #
  metadata = {
    ssh-keys = join("\n", [for key in var.computeSshKeys : "${key.user}:${key.publicKey}"])
  }
  # general logging
  provisioner "local-exec" {
    #
    command = "echo INFO: Virtual machine [${self.name}] setup completed"
  }

} # END => vmInstance
## ---------------------------------------------------
## ---------------------------------------------------
resource "google_dns_record_set" "A" {
  count = var.computeInstances
  #
  name = format("%s%02s.%s", var.computeInstanceKey, count.index, data.google_dns_managed_zone.dnsZone.dns_name)
  type = "A"
  ttl  = 300

  managed_zone = data.google_dns_managed_zone.dnsZone.name

  rrdatas = [resource.google_compute_instance.vmInstance[count.index].network_interface[0].access_config[0].nat_ip]
}
## ---------------------------------------------------
## ---------------------------------------------------
resource "local_file" "ansibleInventory" {
  #
  depends_on = [
    local.vmInstances
  ]
  content = <<-EOD
           #BOF
           [${var.computeInstanceKey}:vars]
           # variable configurations specific to the '${var.computeInstanceKey}' group
           ansible_ssh_private_key_file=${var.computeSshKeys[0]["privateKeyFile"]}
           provisionerSource=terraform
           computeEnvironment=${var.computeEnvironment}
           computeProductKey=${var.computeInstanceKey}
           
           [${var.computeInstanceKey}]
           # members of the '${var.computeInstanceKey}' group
           #%{for vmFqdn in keys(local.vmInstances)}
           ${lower(vmFqdn)} computeNodeType=${local.vmInstances[vmFqdn]["nodeType"]} computeIp=${local.vmInstances[vmFqdn]["ip"]} %{endfor}
           #EOF
          EOD
  #
  filename        = "../ansible/inventory.ini"
  file_permission = "0644"
  # general logging
  provisioner "local-exec" {
    command = "cat ../ansible/inventory.ini"
  }
}
## ---------------------------------------------------
## ---------------------------------------------------
resource "null_resource" "productSetup" {
  #
  depends_on = [
    local_file.ansibleInventory
  ]
  # 
  triggers = {
     "alwaysRun" = formatdate("YYYYMMDDhhmmss", timestamp()),
  }
  #
  provisioner "local-exec" {
    #
    working_dir = "../ansible"
    command     = "ansible-playbook --inventory-file inventory.ini playbook.yml"
  }
}
#
#######################################################################################################################
## ----------------------------------------------------------------------------------------------------------------- ##
#######################################################################################################################
#EOF