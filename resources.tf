data "vsphere_datacenter" "dc" {
  name = "Vivates-Int"
}

data "vsphere_virtual_machine" "template" {
  name          = "cent74tmpl"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}
data "vsphere_datastore" "datastore" {
  name          = "nfs01_esx"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_resource_pool" "pool" {
  name          = "RP-1"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "/Vivates-Int/network/VM Network"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "vm" {
  count            = "1"
  name             = "${var.virtual_machine_name_prefix}${count.index}"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  num_cpus = 2
  memory   = 1024
  guest_id = "rhel7_64Guest"

  cdrom {
    client_device = true
  #  datastore_id = "${data.vsphere_datastore.datastore.id}"
  #  path         = ""
  }
  vapp {
    properties {
      "user-data" = "${base64encode(file("./resources/origin-bastion-init.yml"))}"
    }
  }
  network_interface {
    network_id = "${data.vsphere_network.network.id}"
  }

  disk {
    label = "disk0"
    size = 100
  }
  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    timeout = 90

    customize {

      linux_options {
        host_name = "${var.virtual_machine_name_prefix}${count.index}"
        domain    = "vivates.int"
      }

      network_interface {
        ipv4_address = "${cidrhost(var.virtual_machine_network_address, var.virtual_machine_ip_address_start + count.index)}"
        ipv4_netmask = "${element(split("/", var.virtual_machine_network_address), 1)}"
      }

      dns_server_list = ["172.16.1.1"]
      ipv4_gateway = "172.16.1.1"
    }
  }
}
