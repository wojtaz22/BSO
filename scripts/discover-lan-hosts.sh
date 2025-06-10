#!/usr/bin/env bash
set -euo pipefail

# 1) wykryj interfejs i podsieć
default_route=$(ip route show default | head -n1)
iface=$(awk '/default/ {for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' <<<"$default_route")
cidr=$(ip -o -f inet addr show dev "$iface" | awk '{print $4}')
if [[ -z "$cidr" ]]; then
  echo "ERROR: nie wykryto podsieci" >&2
  exit 1
fi
echo "Podsieć: $cidr (iface $iface)" >&2

# 2) ping-scan nmap
nmap -n -sn "$cidr" -oG - \
  | awk '/Up$/{print $2}'
