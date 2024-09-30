base:
  'minion-nginx':
    - balancer.nginx_install
    - balancer.nginx_conf_balancer
    - balancer.nginx_start
    - iptables.rules_server
    - iptables.rules_drop

  'minion-backend*':
    - balancer.nginx_install
    - balancer.nginx_conf_server
    - balancer.nginx_start
    - iptables.rules_backend
    - iptables.rules_drop