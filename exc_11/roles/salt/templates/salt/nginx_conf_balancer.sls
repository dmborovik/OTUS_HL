/etc/nginx/nginx.conf:
  file.managed:
    - source: salt://balancer/nginx_balancer.conf
    - show_changes: false