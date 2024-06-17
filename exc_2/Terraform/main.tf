terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-b"
}

data "yandex_compute_image" "centos7-image" {
  family = "centos-7"
}


##########Variables##########
variable "cluster_size" {
  type = number
}

variable "cluster" {
  type = string
  description = "name of cluster"  
}

variable "cloud_user" {
  type = string
}

variable "cluster_name" {
  type = string
  description = "A name of a cluster to create"
}

variable "iqn_base" {
  type = string
  default = "iqn.2024-05.ru.ex2"
}

variable "vg_name" {
  type = string
  description = "name of Volume Group"
}

variable "lv_name" {
  type = string
  description = "name of Logical Volume"
}

variable "fs_name" {
  type = string
  description = "name of Cluster file system"
}

###############################

resource "yandex_compute_disk" "gfs2" {
  name = "gfs2"
  type = "network-hdd"
  zone = "ru-central1-b"
  size = "10"  
}

resource "yandex_compute_instance" "target" {
  name = "target"
  hostname = "target"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      name =  "target-boot-disk" 
      image_id = data.yandex_compute_image.centos7-image.id
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet.id}"
    nat       = true
  }

    network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet.id}"
    # nat       = true
  }

  secondary_disk {
    disk_id = yandex_compute_disk.gfs2.id
    device_name = "gfs2"
  }

  metadata = {
    ssh-keys = "centos:${file("~/.ssh/id_ed25519.pub")}"
  }

  provisioner "remote-exec" {
    inline = ["date"]

    connection {
      type        = "ssh"
      user        = "centos"
      private_key = file("~/.ssh/id_ed25519")
      host        = self.network_interface[0].nat_ip_address
    }
  }
}

resource "yandex_compute_instance" "cluster" {
  count = var.cluster_size
  name = "${var.cluster}${count.index + 1}"
  hostname = "${var.cluster}${count.index + 1}"

  resources {
    cores = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      name = "${var.cluster}${count.index + 1}-boot-disk"
      image_id = data.yandex_compute_image.centos7-image.id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "centos:${file("~/.ssh/id_ed25519.pub")}"
  }

  provisioner "remote-exec" {
    inline = ["date"]

    connection {
      type        = "ssh"
      user        = "centos"
      private_key = file("~/.ssh/id_ed25519")
      host        = self.network_interface[0].nat_ip_address
    }
  }
}

resource "yandex_vpc_network" "network" {
  name = "test-network"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "subnet"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "subnet2" {
  name           = "subnet2"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.11.0/24"]
}

resource "local_file" "inventory" {
  filename = "./hosts"
  file_permission = "0644"
  content  = <<EOT
[iscsi_group]
%{ for vm in yandex_compute_instance.target.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
%{ endfor }
[cluster]
%{ for vm in yandex_compute_instance.cluster.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
%{ endfor ~}
EOT
}

resource "local_file" "provision_yml" {
  filename = "./provision.yml"
  file_permission = "0644"
  content = templatefile("provision.yml.tmpl", {
    remote_user=var.cloud_user,
    cluster_name=var.cluster_name,
    cluster_size=var.cluster_size,
    iscsi=yandex_compute_instance.target,
    nodes=yandex_compute_instance.cluster[*],
    iqn_base=var.iqn_base,
    vg_name=var.vg_name,
    lv_name=var.lv_name,
    fs_name=var.fs_name
  })
}

resource "null_resource" "ansible" {
  provisioner "local-exec" {
    command = "ansible-playbook -i ${local_file.inventory.filename} ${local_file.provision_yml.filename}"
    # command = "ansible-playbook -u centos -i '${self.network_interface[0].nat_ip_address},' --private-key ~/.ssh/id_ed25519 provision.yml"
  }
}
