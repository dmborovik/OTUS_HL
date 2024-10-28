terraform {
    required_providers {
        yandex = {
            source = "yandex-cloud/yandex"
        }
    }
    required_version = ">=0.13"
}

provider "yandex" {
    zone = "ru-central1-b"
}

data "yandex_compute_image" "almalinux-9-image"{
    family = "almalinux-9"
}

##########Variable############
variable "cloud_user" {
  type = string
}

variable "consul_number" {
  type = number
}

variable "db_number" {
    type = number
}

variable "backend_number" {
    type = number
}

variable "balancer_number" {
    type = number 
}

variable "ops_number" {
    type = number
}

##############################
######Resource################

resource "yandex_vpc_network" "network" {
    name = "internal"
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

######################################
#########Instance#####################

#########Consul################

resource "yandex_compute_instance" "consul"{
    count    = var.consul_number
    name     = "consul${count.index+1}"
    hostname = "consul${count.index+1}"
    
    resources {
        cores   = 2
        memory  = 2
    }

    boot_disk {
      initialize_params {
        name    = "consul${count.index+1}-boot-disk"
        image_id    = data.yandex_compute_image.almalinux-9-image.id
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
          type = "ssh"
          user = "almalinux"
          private_key = file("~/.ssh/id_ed25519")
          host = self.network_interface[0].nat_ip_address
        }      
    }
}

##########Database##############
resource "yandex_compute_instance" "database"{
    count    = var.db_number
    name     = "db${count.index+1}"
    hostname = "db${count.index+1}"

    resources{
        cores   = 2
        memory  = 2
    }

    boot_disk {
      initialize_params {
        name        = "db${count.index+1}-boot-disk"
        image_id    = data.yandex_compute_image.almalinux-9-image.id
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
          type = "ssh"
          user = "almalinux"
          private_key = file("~/.ssh/id_ed25519")
          host = self.network_interface[0].nat_ip_address
        }      
    }
}

##########ISCSI#################
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
###########Backend##############
resource "yandex_compute_instance" "backend" {
    count    = var.backend_number
    name     = "backend${count.index+1}"
    hostname = "backend${count.index+1}"

    resources{
        cores   = 2
        memory  = 2
    }

    boot_disk {
      initialize_params {
        name        = "backend${count.index+1}-boot-disk"
        image_id    = data.yandex_compute_image.almalinux-9-image.id
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
          type = "ssh"
          user = "almalinux"
          private_key = file("~/.ssh/id_ed25519")
          host = self.network_interface[0].nat_ip_address
        }      
    }  
}

#################balancer###################################
resource "yandex_compute_instance" "balancer" {
    count    = var.balancer_number
    name     = "balancer${count.index+1}"
    hostname = "balancer${count.index+1}"

    resources{
        cores   = 2
        memory  = 2
    }

    boot_disk {
      initialize_params {
        name        = "balancer${count.index+1}-boot-disk"
        image_id    = data.yandex_compute_image.almalinux-9-image.id
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
          type = "ssh"
          user = "almalinux"
          private_key = file("~/.ssh/id_ed25519")
          host = self.network_interface[0].nat_ip_address
        }      
    }  
}

###################Opensearch##############################
resource "yandex_compute_instance" "ops" {
    count    = var.ops_number
    name     = "ops${count.index+1}"
    hostname = "ops${count.index+1}"

    resources{
        cores   = 2
        memory  = 6
    }

    boot_disk {
      initialize_params {
        name        = "ops${count.index+1}-boot-disk"
        image_id    = data.yandex_compute_image.almalinux-9-image.id
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
          type = "ssh"
          user = "almalinux"
          private_key = file("~/.ssh/id_ed25519")
          host = self.network_interface[0].nat_ip_address
        }      
    }  
}

###########################################################
#################FIles#####################################

resource "local_file" "inventory" {
    filename = "./hosts"
    file_permission = "0644"
    content = <<EOT
[consul]
%{ for vm in yandex_compute_instance.consul.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
%{endfor}
[database]
%{ for vm in yandex_compute_instance.database.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
%{endfor}
[targets]
%{ for vm in yandex_compute_instance.iscsi.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
%{ endfor ~}
[backends]
%{ for vm in yandex_compute_instance.backend.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
%{ endfor ~}
[balancer]
%{ for vm in yandex_compute_instance.balancer.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
%{ endfor ~}
[elk]
%{ for vm in yandex_compute_instance.ops.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
%{ endfor ~}


[master]
ops1

EOT
}
  
resource "local_file" "hosts"{
    filename = "./templates/hosts"
    file_permission = "0644"
  content = <<EOT
  127.0.0.1 localhost
%{ for vm in yandex_compute_instance.consul.* ~}
${vm.network_interface.0.ip_address} ${vm.hostname} 
%{endfor}
%{ for vm in yandex_compute_instance.database.* ~}
${vm.network_interface.0.ip_address} ${vm.hostname} 
%{endfor}
${yandex_compute_instance.iscsi.network_interface.0.ip_address}	 ${yandex_compute_instance.iscsi.hostname}
%{ for vm in yandex_compute_instance.backend.* ~}
${vm.network_interface.0.ip_address} ${vm.hostname} 
%{endfor}
%{ for vm in yandex_compute_instance.balancer.* ~}
${vm.network_interface.0.ip_address} ${vm.hostname} 
%{endfor}
%{ for vm in yandex_compute_instance.ops.* ~}
${vm.network_interface.0.ip_address} ${vm.hostname} 
%{endfor}
EOT
}

resource "null_resource" "ansible" {
  provisioner "local-exec" {
    command = "ansible-playbook -i ${local_file.inventory.filename} provision.yml"
  }
}

resource "local_file" "vars" {
  filename = "./group_vars/all.yml"
  file_permission = "0644"
  content = templatefile("group_vars/all.yml.tmpl", {
    remote_user = var.cloud_user
    iscsi=yandex_compute_instance.iscsi
 })
}