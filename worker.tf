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


data "vsphere_datacenter" "dc_worker" {
  name = "QHDC02"
}
data "vsphere_datastore" "datastore_worker" {
  name          = "X2QHDC02-LUN15"
  datacenter_id = data.vsphere_datacenter.dc_worker.id
}
data "vsphere_compute_cluster" "cluster_worker" {
  name          = "HITACHI POC"
  datacenter_id = data.vsphere_datacenter.dc_worker.id
}
data "vsphere_network" "network_worker" {
  name          = "VLAN-164"
  datacenter_id = data.vsphere_datacenter.dc_worker.id
}
data "vsphere_virtual_machine" "template_worker" {
  name          = "INFHAPTPLV03D"
  datacenter_id = data.vsphere_datacenter.dc_worker.id
}

#data "vsphere_resource_pool" "pool" {}

resource "vsphere_virtual_machine" "vm_worker" {
#  count            = 2
  name             = "worker"
  resource_pool_id = data.vsphere_compute_cluster.cluster_worker.resource_pool_id
 # resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore_worker.id
  num_cpus             = 4
  num_cores_per_socket = 1
  memory               = 16096
 # guest_id             = "ubuntu64Guest"
  guest_id         = data.vsphere_virtual_machine.template_worker.guest_id
  scsi_type        = data.vsphere_virtual_machine.template_worker.scsi_type
  nested_hv_enabled    = true
  network_interface {
   # label = "my-network
   # ipv4_address = "172.18.64.154"
   # ipv4_prefix_length = "16"
   # ipv4_gateway = "172.18.64.1"
    network_id   = data.vsphere_network.network_worker.id
    adapter_type = data.vsphere_virtual_machine.template_worker.network_interface_types[0]
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.template_worker.id
  }
  disk {
   size             = data.vsphere_virtual_machine.template_worker.disks.0.size
  # name             = "ubuntu.vmdk"
   label            = "disk1.0"
   thin_provisioned = data.vsphere_virtual_machine.template_worker.disks.0.thin_provisioned
   eagerly_scrub    = data.vsphere_virtual_machine.template_worker.disks.0.eagerly_scrub
  # attach           = true
  # datastore_id     = data.vsphere_datastore.datastore.id

   # size             = var.disksize == "" ? data.vsphere_virtual_machine.template.disks.0.size : var.disksize
   # size             = 40 
  }
  
  
  connection {
    type     = "ssh"
    host     = "${vsphere_virtual_machine.vm_worker.guest_ip_addresses[0]}"
    user     = "qhuser"
    #public_key = file("/home/qhuser/.ssh/my.key.pub")
    password = "RootPassword:"
   # port     = "22"
   # agent    = false
  }
  provisioner "file" {
    source ="/home/qhuser/.ssh/my.key.pub"
    destination ="/home/qhuser/.ssh/authorized_keys"
  } 
  provisioner "file" {
    source ="./worker_key.sh"
    destination ="/home/qhuser/worker_key.sh"
  }
  provisioner "file" {
    source ="./join_key.sh"
    destination ="/home/qhuser/join_key.sh"
  }
  
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
#      "echo RootPassword: | newgrp microk8s",
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "echo RootPassword: | sudo -S chmod 777 /home/qhuser/worker_key.sh",
      "sh /home/qhuser/worker_key.sh",
#      "sudo -S <<< RootPassword: apt install sshpass",
    ]
  }
  provisioner "local-exec" {
    command = "scp qhuser@172.18.64.153:/home/qhuser/.ssh/worker.key.pub ./worker.key.pub"
  }
  provisioner "file" {
    source ="./worker.key.pub"
    destination ="/home/qhuser/.ssh/authorized_keys"
    connection {
      type     = "ssh"
      host     = "172.18.64.152"
      user     = "qhuser"
      password = "RootPassword:"
    }
  }
  provisioner "remote-exec" {
    
    connection {
      type     = "ssh"
      host     = "172.18.64.152"
      user     = "qhuser"
      password = "RootPassword:"
    }
    inline = [
      "cat /home/qhuser/.ssh/my.key.pub >> /home/qhuser/.ssh/authorized_keys",

    ]
  }
  
  provisioner "remote-exec" {
    inline = [
      "echo RootPassword: | sudo -S chmod 777 /home/qhuser/join_key.sh",
      "/bin/bash /home/qhuser/join_key.sh",
#      "sudo -S <<< RootPassword: apt install sshpass",
    ]
  }
}
