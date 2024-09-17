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

######Backend#######

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
#####balancer#########
resource "yandex_compute_instance" "balancer" {
  name = "balancer"
  hostname = "balancer"

  resources {
    cores   = 2
    memory  = 6
  }

  boot_disk {
    initialize_params {
      name      = "balancer-boot-disk"
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

#######Consul##########
resource "yandex_compute_instance" "csl1" {
  name = "csl1"
  hostname = "csl1"

  resources {
    cores   = 2
    memory  = 6
  }

  boot_disk {
    initialize_params {
      name      = "csl1-boot-disk"
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

resource "yandex_compute_instance" "csl2" {
  name = "csl2"
  hostname = "csl2"

  resources {
    cores   = 2
    memory  = 6
  }

  boot_disk {
    initialize_params {
      name      = "csl2-boot-disk"
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

resource "yandex_compute_instance" "csl3" {
  name = "csl3"
  hostname = "csl3"

  resources {
    cores   = 2
    memory  = 6
  }

  boot_disk {
    initialize_params {
      name      = "csl3-boot-disk"
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
[databases]
%{ for vm in yandex_compute_instance.database.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
%{ endfor }
[backends]
%{ for vm in yandex_compute_instance.backend1.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no' 
%{ endfor }
%{ for vm in yandex_compute_instance.backend2.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no' 
%{ endfor }
[consul]
%{ for vm in yandex_compute_instance.csl1.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
%{ endfor }
%{ for vm in yandex_compute_instance.csl2.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
%{ endfor }
%{ for vm in yandex_compute_instance.csl3.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
%{ endfor }
[balancers]
%{ for vm in yandex_compute_instance.balancer.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
%{ endfor }

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
${yandex_compute_instance.database.network_interface.0.ip_address}	${yandex_compute_instance.database.hostname}
${yandex_compute_instance.backend1.network_interface.0.ip_address}	${yandex_compute_instance.backend1.hostname} 
${yandex_compute_instance.balancer.network_interface.0.ip_address}	${yandex_compute_instance.balancer.hostname} 
${yandex_compute_instance.backend2.network_interface.0.ip_address}	${yandex_compute_instance.backend2.hostname} 
${yandex_compute_instance.csl1.network_interface.0.ip_address}	${yandex_compute_instance.csl1.hostname} 
${yandex_compute_instance.csl2.network_interface.0.ip_address}	${yandex_compute_instance.csl2.hostname} 
${yandex_compute_instance.csl3.network_interface.0.ip_address}	${yandex_compute_instance.csl3.hostname} 
EOT
}

resource "null_resource" "ansible" {
  provisioner "local-exec" {
    command = "ansible-playbook -i ${local_file.inventory.filename} provision.yml"
  }
}