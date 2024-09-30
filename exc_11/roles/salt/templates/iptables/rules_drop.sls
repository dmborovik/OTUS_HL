drop_input:
  iptables.set_policy:
    - chain: INPUT
    - policy: DROP   