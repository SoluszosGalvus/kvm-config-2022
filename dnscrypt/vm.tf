terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.6.14"
    }
  }
}

provider "libvirt" {
  uri = "qemu+ssh://emet-selch@10.10.1.2/system?keyfile=/root/.ssh/id_rsa&sshauth=privkey"
}

resource "libvirt_volume" "cloud-image" {
  name = "opensuselp153"
  pool = "default"
  source = "https://download.opensuse.org/pub/opensuse/distribution/leap/15.3/appliances/openSUSE-Leap-15.3-JeOS.x86_64-15.3-OpenStack-Cloud-Current.qcow2"
  format = "qcow2"
}

resource "libvirt_volume" "os-image" {
  name = "AI-DNSCRYPT-001"
  pool = "vms1"
  base_volume_id = libvirt_volume.cloud-image.id
  size = 15 * 1024 * 1024 * 1024
}

resource "libvirt_cloudinit_disk" "cloud-init" {
  name = "dnscrypt-cloudinit.iso"
  pool = "vms1"
  user_data = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
}


data "template_file" "user_data" {
  template = file("cloud-init.cfg")
}

data "template_file" "network_config" {
  template = file("network.cfg")
}

resource "libvirt_domain" "vm" {
  qemu_agent = true
  name = "AI-DNSCRYPT-001"

  memory = 1 * 1024
  
  vcpu = 1

  cloudinit = libvirt_cloudinit_disk.cloud-init.id

  disk {
    volume_id = libvirt_volume.os-image.id
  }

  network_interface {
    bridge = "vmbr"
  }
  graphics {
    type = "spice"
    listen_type = "address"
    autoport = "true"
  }
}