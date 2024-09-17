consul {
  address = "localhost:8500"

  retry {
    enabled  = true
    attempts = 12
    backoff  = "250ms"
  }
}
template {
  source      = "/usr/local/consul/templates/web.conf.ctmpl"
  destination = "/etc/nginx/conf.d/web.conf"
  perms       = 0600
  command     = "sudo systemctl stop nginx && sudo systemctl start nginx"
}