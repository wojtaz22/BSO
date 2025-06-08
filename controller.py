#!/usr/bin/env python3
import argparse, os, signal, subprocess, sys, time
import schedule
import smtplib
from email.message import EmailMessage

parser = argparse.ArgumentParser(description="BSO Controller: SSH tunnel + GVM scan + email report")
parser.add_argument("--host",     required=True, help="adres serwera/skanera")
parser.add_argument("--user",     required=True, help="użytkownik SSH")
parser.add_argument("--local-port", type=int, default=8000, help="port lokalny tunelu")
parser.add_argument("--remote-port",type=int, default=8080, help="port na serwerze")
parser.add_argument("--interval", type=int, default=60, help="interwał skanowania [min]")
parser.add_argument("--email-to", required=True, help="adres e-mail do raportu")
parser.add_argument("action", choices=["start","stop"], help="start lub stop usługi")
args = parser.parse_args()

PID_FILE = "/tmp/bso_controller.pid"

def create_ssh_tunnel():
    cmd = [
        "ssh", "-fN",
        "-L", f"{args.local_port}:localhost:{args.remote_port}",
        f"{args.user}@{args.host}"
    ]
    subprocess.run(cmd, check=True)
    print("Tunel SSH uruchomiony")

def run_scan():
    # wywołanie lokalne GVM (jeśli GVM w tym samym kontenerze)
    subprocess.run(["gvm-cli", "socket", "--socketfile", "/run/ospd/ospd-openvas.sock", "scan", "--schedule", "Full and fast"], check=True)
    fetch_report()
    send_report_email()

def fetch_report():
    # zakładamy, że GVM zapisuje raport w /var/lib/gvm/reports/latest_report.pdf
    subprocess.run(["cp", "/var/lib/gvm/reports/latest_report.pdf", "."], check=True)
    print("Pobrano raport")

def send_report_email():
    msg = EmailMessage()
    msg["Subject"] = "BSO – nowy raport skanowania"
    msg["From"] = "noreply@yourdomain.com"
    msg["To"] = args.email_to
    with open("latest_report.pdf", "rb") as f:
        msg.add_attachment(f.read(), maintype="application", subtype="pdf", filename="report.pdf")
    with smtplib.SMTP("smtp.yourprovider.com") as smtp:
        smtp.send_message(msg)
    print("Wysłano raport na e-mail")

def schedule_jobs():
    schedule.every(args.interval).minutes.do(run_scan)
    print(f"Harmonogram: co {args.interval} minut skanowanie")
    while True:
        schedule.run_pending()
        time.sleep(1)

def write_pid():
    with open(PID_FILE, "w") as f:
        f.write(str(os.getpid()))

if args.action == "start":
    create_ssh_tunnel()
    write_pid()
    run_scan()
    schedule_jobs()

elif args.action == "stop":
    try:
        pid = int(open(PID_FILE).read())
        os.kill(pid, signal.SIGTERM)
        print("Usługa BSO zatrzymana")
    except Exception:
        print("Nie udało się zatrzymać usługi")
    sys.exit(0)
