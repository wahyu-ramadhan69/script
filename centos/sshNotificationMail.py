import ssl
import socket
from datetime import datetime
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import csv  # Import modul csv

def get_certificate_expiration_date(hostname):
    context = ssl.create_default_context()
    with socket.create_connection((hostname, 443)) as sock:
        with context.wrap_socket(sock, server_hostname=hostname) as ssock:
            cert = ssock.getpeercert()
            timestamp = cert['notAfter']
            expiration_date = datetime.strptime(timestamp, '%b %d %H:%M:%S %Y %Z')
            return expiration_date

def send_email(to_email, subject, body):
    from_email = "it_infra@bcaf.id"  # Ganti dengan alamat email Anda
    password = "cpeyqoewqmrxuvsn"     # Ganti dengan kata sandi email Anda

    msg = MIMEMultipart()
    msg['From'] = from_email
    msg['To'] = to_email
    msg['Subject'] = subject

    msg.attach(MIMEText(body, 'plain'))

    server = smtplib.SMTP('smtp.gmail.com', 587)
    server.starttls()
    server.login(from_email, password)
    text = msg.as_string()
    server.sendmail(from_email, to_email, text)
    server.quit()

# Fungsi untuk membaca website dari file CSV
def read_websites_from_csv(filepath):
    websites = []
    with open(filepath, newline='') as csvfile:
        reader = csv.reader(csvfile)
        next(reader)  # Lewati header
        for row in reader:
            websites.append(row[0])  # Langsung gunakan hostname
    return websites

# Ganti dengan path ke file CSV Anda
filepath = 'websites.csv'
websites = read_websites_from_csv(filepath)

for website in websites:
    try:
        expiration_date = get_certificate_expiration_date(website)
        remaining_days = (expiration_date - datetime.now()).days
        print(remaining_days)
        if remaining_days < 365:
            subject = f"Peringatan: Sertifikat untuk {website} akan kedaluwarsa"
            body = f"Sertifikat untuk {website} akan kedaluwarsa dalam {remaining_days} hari. Segera perbarui sertifikat."
            send_email("it_infra@bcaf.id", subject, body)
    except Exception as e:
        print(f"Error checking {website}: {e}")