terraform {
  required_providers {
    vsphere = {
      source = "hashicorp/vsphere"
      version = "2.2.0"
    }
  }
}
provider "vsphere" {
  user                 = "dhanashri01.c@quickheal.com"
  password             = "Quick@#$16"
  vsphere_server       = "qhvc-02.vm.qhtpl.com"
  allow_unverified_ssl = true
}


data "vsphere_datacenter" "dc" {
  name = "QHDC02"
}
data "vsphere_datastore" "datastore" {
  name          = "X2QHDC02-LUN15"
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_compute_cluster" "cluster" {
  name          = "HITACHI POC"
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_network" "network" {
  name          = "VLAN-164"
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_virtual_machine" "template" {
  name          = "INFHAPTPLV02D"
  datacenter_id = data.vsphere_datacenter.dc.id
}

#data "vsphere_resource_pool" "pool" {}

resource "vsphere_virtual_machine" "vm" {
  name             = "ubuntu"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
 # resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus             = 8
  num_cores_per_socket = 1
  memory               = 16096
 # guest_id             = "ubuntu64Guest"
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  scsi_type        = data.vsphere_virtual_machine.template.scsi_type
  nested_hv_enabled    = true
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
  disk {
   size             = data.vsphere_virtual_machine.template.disks.0.size
  # name             = "ubuntu.vmdk"
   label            = "disk.0"
   thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
   eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
  # attach           = true
  # datastore_id     = data.vsphere_datastore.datastore.id

   # size             = var.disksize == "" ? data.vsphere_virtual_machine.template.disks.0.size : var.disksize
   # size             = 40 
  }

  connection {
    type     = "ssh"
    host     = "${vsphere_virtual_machine.vm.guest_ip_addresses[0]}"
    user     = "qhuser"
    password = "RootPassword:"
   # port     = "22"
   # agent    = false
  }
 # provisioner "file" {
  #  source ="microk8s.sh"
  #  destination ="/home/microk8s.sh"
 # }
  provisioner "remote-exec" {
    inline = [
      "touch abc.txt",
#      "passwd = RootPassword:,
#      "echo $passwd",
#      "sudo -S sh -c 'echo $USER ALL=(ALL) NOPASSWD:ALL >> /etc/sudoers'",
      "echo RootPassword: | sudo -S snap install microk8s --classic --channel=1.22/stable",
#      "echo RootPassword: | sudo -S usermod -a -G microk8s qhuser",
#      "echo RootPassword: | sudo -S chown -R -f qhuser ~/.kube, 
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "echo RootPassword: | sudo -S usermod -a -G microk8s qhuser",
      "newgrp microk8s",
    ]
  }
  provisioner "file" {
    source ="/home/qhuser/.ssh/my.key.pub"
    destination ="/home/qhuser/.ssh/my.key.pub"
  } 

}
