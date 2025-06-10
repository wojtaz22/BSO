#!/bin/bash
docker exec -it greenbone-cli bash -c "apt update && apt install -y --no-install-recommends nmap iproute2 && /opt/scripts/discover-lan-hosts.sh"
