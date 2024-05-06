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

resource "yandex_compute_disk" "boot-disk" {
  name     = "boot-disk"
  type     = "network-hdd"
  zone     = "ru-central1-b"
  size     = "10"
  image_id = "fd89nebr9a651021u19i"
}



resource "yandex_compute_instance" "vm-1" {
  name = "test-vm-1"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "debian:${file("~/.ssh/id_ed25519.pub")}"
  }

  provisioner "remote-exec" {
    inline = ["sudo apt update -y"]

    connection {
      type        = "ssh"
      user        = "debian"
      private_key = file("~/.ssh/id_ed25519")
      host        = self.network_interface[0].nat_ip_address
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -u debian -i '${self.network_interface[0].nat_ip_address},' --private-key ~/.ssh/id_ed25519 provision.yml"
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

