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

data "yandex_compute_image" "almalinux-9-image" {
    family = "almalinux-9"
}

#####Variables######
variable "cloud_user"{
  type = string
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

######Opensearch######
resource "yandex_compute_instance" "ops" {
  name = "ops"
  hostname = "ops"

  resources {
    cores   = 4
    memory  = 8
  }

  boot_disk {
    initialize_params {
      name      = "ops-boot-disk"
      image_id  = data.yandex_compute_image.almalinux-9-image.id      
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.internal_subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "almalinux:${file("~/.ssh/id_ed25519.pub")}"
  }

  provisioner "remote-exec" {
    inline = [ "date" ]

    connection {
      type        = "ssh"
      user        = "almalinux"
      private_key = file("~/.ssh/id_ed25519")
      host        = self.network_interface[0].nat_ip_address
    }
  }
}

######Backend#######

resource "yandex_compute_instance" "backend" {
  name = "backend"
  hostname = "backend"

  resources {
    cores   = 2
    memory  = 2
  }

  boot_disk {
    initialize_params {
      name      = "backend-boot-disk"
      image_id  = data.yandex_compute_image.almalinux-9-image.id      
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.internal_subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "almalinux:${file("~/.ssh/id_ed25519.pub")}"
  }

  provisioner "remote-exec" {
    inline = [ "date" ]

    connection {
      type        = "ssh"
      user        = "almalinux"
      private_key = file("~/.ssh/id_ed25519")
      host        = self.network_interface[0].nat_ip_address
    }
  }
}

#####Kafka#########
resource "yandex_compute_instance" "kfk" {
  name = "kfk"
  hostname = "kfk"

  resources {
    cores   = 2
    memory  = 6
  }

  boot_disk {
    initialize_params {
      name      = "kfk-boot-disk"
      image_id  = data.yandex_compute_image.almalinux-9-image.id      
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.internal_subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "almalinux:${file("~/.ssh/id_ed25519.pub")}"
  }

  provisioner "remote-exec" {
    inline = [ "date" ]

    connection {
      type        = "ssh"
      user        = "almalinux"
      private_key = file("~/.ssh/id_ed25519")
      host        = self.network_interface[0].nat_ip_address
    }
  }
}

#######hosts#######
resource "local_file" "inventory" {
  filename = "./hosts"
  file_permission = "0644"
  content  = <<EOT
[ops]
%{ for vm in yandex_compute_instance.ops.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no' 
%{ endfor }
[backends]
%{ for vm in yandex_compute_instance.backend.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no' 
%{ endfor }
[kafka]
%{ for vm in yandex_compute_instance.kfk.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
%{ endfor }

[vector]
backends
kafka
EOT
}

resource "local_file" "vars" {
  filename = "./group_vars/all.yml"
  file_permission = "0644"
  content = templatefile("group_vars/all.yml.tmpl", {
    remote_user = var.cloud_user
 })
}

resource "local_file" "hosts" {
  filename = "./templates/hosts"
  file_permission = "0644"
 content  = <<EOT
127.0.0.1	localhost
${yandex_compute_instance.ops.network_interface.0.ip_address}	${yandex_compute_instance.ops.hostname} 
${yandex_compute_instance.backend.network_interface.0.ip_address}	${yandex_compute_instance.backend.hostname} 
${yandex_compute_instance.kfk.network_interface.0.ip_address}	${yandex_compute_instance.kfk.hostname} 
EOT
}

resource "null_resource" "ansible" {
  provisioner "local-exec" {
    command = "ansible-playbook -i ${local_file.inventory.filename} provision.yml"
  }
}