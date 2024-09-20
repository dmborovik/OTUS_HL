terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.14"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://192.168.56.101:8006/api2/json"
  pm_api_token_id = "root@pam!root_token"
  pm_api_token_secret = "227aeaac-5fc6-4348-9b00-e1b96e5e9616"
  pm_tls_insecure = true
}