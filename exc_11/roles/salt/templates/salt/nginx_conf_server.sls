/etc/nginx/nginx.conf:
  file.managed:
    - source: salt://balancer/nginx_server.conf
    - show_changes: false