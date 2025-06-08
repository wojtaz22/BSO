# 1) baza: gotowy, sprawdzony GVM-Docker
FROM ghcr.io/netizencorp/gvm-docker:latest

# 2) katalog na nasz komponent
WORKDIR /opt/bso

# 3) doinstaluj Pythona i pip (jeśli w obrazie nie ma)
USER root
RUN apt-get update \
 && apt-get install -y python3 python3-pip \
 && rm -rf /var/lib/apt/lists/*

# 4) skopiuj nasze pliki
COPY .gitattributes requirements.txt controller.py entrypoint.sh ./

# 5) zainstaluj zależności kontrolera
RUN pip3 install --no-cache-dir -r requirements.txt \
 && chmod +x entrypoint.sh controller.py

# 6) startuj wrapper, który uruchomi GVM, a potem kontroler
ENTRYPOINT ["./entrypoint.sh"]