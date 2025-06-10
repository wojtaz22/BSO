#!/usr/bin/env bash
set -euo pipefail

# 1. Uruchom skrypt wykrywający hosty (przez run.sh)
./run.sh

# 2. Pobierz wynik działania skryptu wykrywającego hosty
HOSTS=$(docker exec greenbone-cli bash -c "/opt/scripts/discover-lan-hosts.sh")

if [[ -z "$HOSTS" ]]; then
  echo "Nie wykryto żadnych hostów."
  exit 0
fi

# 3. Wykonaj skanowanie każdego hosta z wykorzystaniem gvm-cli
for ip in $HOSTS; do
  echo "Skanuję hosta: $ip"
  
  docker exec greenbone-cli gvm-cli socket --gmp-username admin --gmp-password admin <<EOF
<create_target>
  <name>Scan-$ip</name>
  <hosts>$ip</hosts>
</create_target>
EOF

  # W prawdziwym użyciu: pobierz ID celu i uruchom zadanie
  # Można też automatycznie sprawdzać listę tasków i statusy.
done
