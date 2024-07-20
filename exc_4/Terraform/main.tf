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

resource "yandex_compute_disk" "gfs2" {
  name = "gfs2"
  type = "network-hdd"
  zone = "ru-central1-b"
  size = "10"  
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

########iscsi#######
resource "yandex_compute_instance" "iscsi" {
  name      = "iscsi"
  hostname  = "iscsi"

  resources {
    cores   = 2
    memory  = 2
  }

  boot_disk {
    initialize_params {
      name      = "iscsi-boot-disk"
      image_id  = data.yandex_compute_image.almalinux-9-image.id      
    }
  }

  secondary_disk {
    disk_id = yandex_compute_disk.gfs2.id
    device_name = "gfs2"
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

######backends######
resource "yandex_compute_instance" "backend1" {
  name      = "backend1"
  hostname  = "backend1"

  resources {
    cores   = 2
    memory  = 2
  }

  boot_disk {
    initialize_params {
      name      = "backend1-boot-disk"
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
    inline = ["date"]

    connection {
      type        = "ssh"
      user        = "almalinux"
      private_key = file("~/.ssh/id_ed25519")
      host        = self.network_interface[0].nat_ip_address
    }
  }
}

resource "yandex_compute_instance" "backend2" {
  name      = "backend2"
  hostname  = "backend2"

  resources {
    cores   = 2
    memory  = 2
  }

  boot_disk {
    initialize_params {
      name      = "backend2-boot-disk"
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
    inline = ["date"]

    connection {
      type        = "ssh"
      user        = "almalinux"
      private_key = file("~/.ssh/id_ed25519")
      host        = self.network_interface[0].nat_ip_address
    }
  }
}
######balancers######
resource "yandex_lb_target_group" "backends" {
  name = "balance-backend"

  target {
    subnet_id = "${yandex_vpc_subnet.internal_subnet.id}"
    address   = "${yandex_compute_instance.backend1.network_interface.0.ip_address}"
  }

    target {
    subnet_id = "${yandex_vpc_subnet.internal_subnet.id}"
    address   = "${yandex_compute_instance.backend2.network_interface.0.ip_address}"
  }
  
}

resource "yandex_lb_network_load_balancer" "balancer" {

  name = "load-balancer"
  # type = "internal"
  listener {
    name = "listener"
    port = 80
    target_port = 80
    protocol = "tcp"
    external_address_spec {
      ip_version = "ipv4"
    }
  }
  attached_target_group {
    target_group_id = "${yandex_lb_target_group.backends.id}"
    healthcheck{
      name                = "http"
      interval            = 2
      timeout             = 1
      unhealthy_threshold = 2
      healthy_threshold   = 2
      http_options {
        port  = 80
        path  = "/api"
      }
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
%{ for vm in yandex_compute_instance.backend1.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
%{ endfor ~}
%{ for vm in yandex_compute_instance.backend2.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
%{ endfor ~}
[targets]
%{ for vm in yandex_compute_instance.iscsi.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
%{ endfor ~}
EOT
}

resource "local_file" "vars" {
  filename = "./group_vars/all.yml"
  file_permission = "0644"
  content = templatefile("group_vars/all.yml.tmpl", {
    remote_user = var.cloud_user
    iscsi       = yandex_compute_instance.iscsi
  })
}

resource "local_file" "hosts" {
  filename = "./templates/hosts"
  file_permission = "0644"
 content  = <<EOT
127.0.0.1	localhost
${yandex_compute_instance.backend1.network_interface.0.ip_address}	${yandex_compute_instance.backend1.hostname}
${yandex_compute_instance.backend2.network_interface.0.ip_address}	${yandex_compute_instance.backend2.hostname}
${yandex_compute_instance.database.network_interface.0.ip_address}	${yandex_compute_instance.database.hostname}
${yandex_compute_instance.iscsi.network_interface.0.ip_address}	 ${yandex_compute_instance.iscsi.hostname}
EOT
}

# resource "null_resource" "ansible" {
#   provisioner "local-exec" {
#     command = "ansible-playbook -i ${local_file.inventory.filename} provision.yml"
#   }
# }