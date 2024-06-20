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

#####Variables######
variable "cloud_user"{
  type = string
}

variable "backend_number" {
  type = number
}
####################
######Resource######
resource "yandex_vpc_network" "network" {
  name  = "internal"
}

resource "yandex_vpc_subnet" "internal_subnet" {
  name = "internal_subnet"
  zone = "ru-central1-b"
  network_id = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}


####################
######Instance######

######database######
resource "yandex_compute_instance" "database" {
  name = "database"
  hostname = "database"

  resources {
    cores   = 2
    memory  = 2
  }

  boot_disk {
    initialize_params {
      name      = "database-boot-disk"
      image_id  = data.yandex_compute_image.centos7-image.id      
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.internal_subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "centos:${file("~/.ssh/id_ed25519.pub")}"
  }

  provisioner "remote-exec" {
    inline = [ "date" ]

    connection {
      type        = "ssh"
      user        = "centos"
      private_key = file("~/.ssh/id_ed25519")
      host        = self.network_interface[0].nat_ip_address
    }
  }
}

######backends######
resource "yandex_compute_instance" "backend" {
  count     = var.backend_number
  name      = "backend${count.index+1}"
  hostname  = "backend${count.index+1}"

  resources {
    cores   = 2
    memory  = 2
  }

  boot_disk {
    initialize_params {
      name      = "backend${count.index +1}-boot-disk"
      image_id  = data.yandex_compute_image.centos7-image.id
  }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.internal_subnet.id
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

######balancer######
resource "yandex_compute_instance" "balancer" {
  name = "balancer"
  hostname = "balancer"

  resources {
    cores   = 2
    memory  = 2
  }

  boot_disk {
    initialize_params {
      name      = "balancer-boot-disk"
      image_id  = data.yandex_compute_image.centos7-image.id      
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.internal_subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "centos:${file("~/.ssh/id_ed25519.pub")}"
  }

  


  provisioner "remote-exec" {
    inline = [ "date" ]

    connection {
      type        = "ssh"
      user        = "centos"
      private_key = file("~/.ssh/id_ed25519")
      host        = self.network_interface[0].nat_ip_address
    }
  }
}
####################
#######hosts#######
resource "local_file" "inventory" {
  filename = "./hosts"
  file_permission = "0644"
  content  = <<EOT
[databases]
%{ for vm in yandex_compute_instance.database.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
%{ endfor }
[backend]
%{ for vm in yandex_compute_instance.backend.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
%{ endfor ~}
[balancers]
%{ for vm in yandex_compute_instance.balancer.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
%{ endfor }
EOT
}

resource "null_resource" "ansible" {
  provisioner "local-exec" {
    command = "ansible-playbook -i ${local_file.inventory.filename} provision.yml"
  }
}