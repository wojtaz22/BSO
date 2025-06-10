#!/usr/bin/env bash
set -euo pipefail

# wczytanie .env
source /opt/scripts/.env

# 1) discovery LAN
mapfile -t HOSTS < <( /opt/scripts/discover-lan-hosts.sh )
if [ ${#HOSTS[@]} -eq 0 ]; then
  echo "Brak żywych hostów – pomijam."
  exit 0
fi
echo "Hosty: ${HOSTS[*]}"

# 2) argumenty ++hosts
HOSTS_ARGS=( ++hosts "${HOSTS[@]}" )
PORT_ARGS=( ++port-list-id "$PORT_LIST_ID" )
NAME_ARGS=( ++name "$TARGET_NAME" )
RECIPIENT_ARGS=( ++recipient "$RECIPIENT" )
SENDER_ARGS=( ++sender "$SENDER" )

# 3) uruchomienie skryptu GVM-Script
gvm-script \
  --gmp-username "$GMP_USER" \
  --gmp-password "$GMP_PASS" \
  /opt/scripts/start-alert-scan.gmp.py \
  "${HOSTS_ARGS[@]}" \
  "${PORT_ARGS[@]}" \
  "${NAME_ARGS[@]}" \
  "${RECIPIENT_ARGS[@]}" \
  "${SENDER_ARGS[@]}"

# 4) (opcjonalnie) czekaj i pobierz raport
echo "Czekam $SCAN_WAIT s"
sleep "$SCAN_WAIT"
gvm-script \
  --gmp-username "$GMP_USER" \
  --gmp-password "$GMP_PASS" \
  /opt/scripts/get-report.gmp.py \
  ++format pdf > /opt/scripts/latest_report.pdf

# 5) wyślij e-mail przez msmtp
echo -e "Subject: BSO report\n\nZobacz w załączniku." \
  | msmtp --from="$SENDER" -t "$RECIPIENT" -a default -A default \
  -a attachment /opt/scripts/latest_report.pdf

echo "✔️ Auto-scan ukończony."
