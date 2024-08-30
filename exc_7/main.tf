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

######ELK######
resource "yandex_compute_instance" "elk1" {
  name = "elk1"
  hostname = "elk1"

  resources {
    cores   = 4
    memory  = 8
  }

  boot_disk {
    initialize_params {
      name      = "elk1-boot-disk"
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

resource "yandex_compute_instance" "elk2" {
  name = "elk2"
  hostname = "elk2"

  resources {
    cores   = 2
    memory  = 6
  }

  boot_disk {
    initialize_params {
      name      = "elk2-boot-disk"
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

resource "yandex_compute_instance" "elk3" {
  name = "elk3"
  hostname = "elk3"

  resources {
    cores   = 2
    memory  = 6
  }

  boot_disk {
    initialize_params {
      name      = "elk3-boot-disk"
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
[elk]
%{ for vm in yandex_compute_instance.elk1.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no' roles=data,master
%{ endfor }
%{ for vm in yandex_compute_instance.elk2.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no' roles=data,ingest
%{ endfor }
%{ for vm in yandex_compute_instance.elk3.* ~}
${vm.hostname} ansible_host=${vm.network_interface.0.nat_ip_address} ansible_ssh_common_args='-o StrictHostKeyChecking=no' roles=data,ingest
%{ endfor }

[master]
elk1
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
${yandex_compute_instance.elk1.network_interface.0.ip_address}	${yandex_compute_instance.elk1.hostname} 
${yandex_compute_instance.elk2.network_interface.0.ip_address}	${yandex_compute_instance.elk2.hostname} 
${yandex_compute_instance.elk3.network_interface.0.ip_address}	${yandex_compute_instance.elk3.hostname} 
EOT
}

resource "null_resource" "ansible" {
  provisioner "local-exec" {
    command = "ansible-playbook -i ${local_file.inventory.filename} provision.yml"
  }
}