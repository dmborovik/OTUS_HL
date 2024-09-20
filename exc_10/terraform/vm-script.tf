resource "proxmox_vm_qemu" "ubuntu2204" {
    name = "Ununtu2204"
    desc = "A test for using terraform and cloudinit"

    # Node name has to be the same name as within the cluster
    # this might not include the FQDN
    target_node = "pve1"

    # The template name to clone this vm from
    clone = "Ubuntu2204-Template"

    # Activate QEMU agent for this VM
    agent = 1

    os_type = "cloud-init"
    cores = 1
    sockets = 1
    vcpus = 0
    cpu = "host"
    memory = 1024
    scsihw = "virtio-scsi-single"

    # Setup the disk
    # disks {
    #     ide {
    #         ide3 {
    #             cloudinit {
    #                 storage = "HDD500"
    #             }
    #         }
    #     }
    #     virtio {
    #         virtio0 {
    #             disk {
    #                 size            = "2252M"
    #                 storage         = "HDD500"
    #                 replicate       = true
    #             }
    #         }
    #     }
    # }
  disk {
    slot = 0
    # set disk size here. leave it small for testing because expanding the disk takes time.
    size = "10G"
    type = "scsi"
    storage = "local"
    iothread = 1
  }
  #   # Setup the network interface and assign a vlan tag: 256
    network {
        model = "virtio"
        bridge = "vmbr0"
    }

    # Setup the ip address using cloud-init.
    # boot = "order=virtio0"
    # Keep in mind to use the CIDR notation for the ip.
    ipconfig0 = "ip=dhcp"
    nameserver = "8.8.8.8"
    ciuser = "user"
}