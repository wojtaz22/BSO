#!/bin/bash
set -e

# a) oryginalny entrypoint GVM (startuje gvmd, ospd-openvas itd.)
#    Ścieżkę sprawdź w ich repo – najpewniej /usr/local/bin/docker-entrypoint.sh
/docker-entrypoint.sh &

# b) czekamy na gotowość GVM
echo "Czekam na gotowość GVM…"
until gvm-cli socket --socketfile /run/ospd/ospd-openvas.sock info; do
  sleep 5
done

# c) uruchamiamy nasz kontroler
exec python3 controller.py "$@"
