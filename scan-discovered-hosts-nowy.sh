#!/usr/bin/env bash
set -euo pipefail

# Dane logowania do GVM
GVM_USER="admin"
GVM_PASS="admin"

# 1. Uruchom wykrywanie hostów
./run.sh

# 2. Pobierz wykryte hosty
HOSTS=$(docker exec greenbone-cli bash -c "/opt/scripts/discover-lan-hosts.sh")

if [[ -z "$HOSTS" ]]; then
  echo "Nie wykryto żadnych hostów."
  exit 0
fi

# 3. Pobierz domyślny scanner_id dynamicznie
SCANNER_ID=$(docker exec --user 1000:1000 greenbone-cli gvm-cli socket \
  --gmp-username "$GVM_USER" --gmp-password "$GVM_PASS" <<EOF | xmllint --xpath "string(//scanner[1]/@id)" -
<get_scanners/>
EOF
)

echo "Wykryto scanner ID: $SCANNER_ID"

# 4. Przetwarzaj każdego hosta
for ip in $HOSTS; do
  echo "Przetwarzanie hosta: $ip"

  # Utwórz target
  TARGET_XML=$(docker exec --user 1000:1000 greenbone-cli gvm-cli socket \
    --gmp-username "$GVM_USER" --gmp-password "$GVM_PASS" <<EOF
<create_target>
  <name>Target-$ip</name>
  <hosts>$ip</hosts>
</create_target>
EOF
  )

  TARGET_ID=$(echo "$TARGET_XML" | xmllint --xpath 'string(//create_target_response/@id)' -)

  echo "TARGET ID: $TARGET_ID"

  # Utwórz task
  TASK_XML=$(docker exec --user 1000:1000 greenbone-cli gvm-cli socket \
    --gmp-username "$GVM_USER" --gmp-password "$GVM_PASS" <<EOF
<create_task>
  <name>Scan-$ip</name>
  <target id="$TARGET_ID"/>
  <scanner id="$SCANNER_ID"/>
</create_task>
EOF
  )

  TASK_ID=$(echo "$TASK_XML" | xmllint --xpath 'string(//create_task_response/@id)' -)
  echo "TASK ID: $TASK_ID"

  # Uruchom task
  docker exec --user 1000:1000 greenbone-cli gvm-cli socket \
    --gmp-username "$GVM_USER" --gmp-password "$GVM_PASS" <<EOF
<start_task task_id="$TASK_ID"/>
EOF

  echo "Skanowanie hosta $ip rozpoczęte"

done

echo "Wszystkie skany zostały uruchomione."
