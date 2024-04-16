import subprocess
import datetime
import csv
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

def check_ssl_expiry(domain):
    # Menjalankan perintah openssl untuk mendapatkan informasi sertifikat
    command = f"echo | openssl s_client -servername {domain} -connect {domain}:443 2>/dev/null | openssl x509 -noout -dates"
    command = f"echo | openssl s_client -servername {domain} -connect {domain}:443 2>&1 | openssl x509 -noout -dates"
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error: {result.stderr}")
        return
    output = result.stdout
    start_date_str = None
    end_date_str = None
    for line in output.splitlines():
        if line.startswith('notBefore='):
            start_date_str = line.split('=')[1].strip()
        elif line.startswith('notAfter='):
            end_date_str = line.split('=')[1].strip()

    if end_date_str:
        end_date = datetime.datetime.strptime(end_date_str, '%b %d %H:%M:%S %Y %Z')
        today = datetime.datetime.now()
        delta = end_date - today
        if delta.days < 300:
            print(f"Sertifikat SSL untuk {domain} akan kadaluarsa dalam {delta.days} hari.")
            subject = f"Peringatan: Sertifikat untuk {domain} akan kedaluwarsa"
            body = f"Sertifikat untuk {domain} akan kedaluwarsa dalam {delta.days} hari. Segera perbarui sertifikat."
            send_email("wahyu.ramadhani6969@gmail.com", subject, body)
        else:
            print(f"Sertifikat SSL untuk {domain} masih valid untuk {delta.days} hari lagi.")
    else:
        print("Tidak dapat menemukan tanggal kadaluwarsa sertifikat.")

def check_domains_from_csv(file_path):
    with open(file_path, newline='') as csvfile:
        domain_reader = csv.reader(csvfile)
        for row in domain_reader:
            if row:  # Memastikan baris tidak kosong
                domain = row[0]
                print(f"Memeriksa domain: {domain}")
                check_ssl_expiry(domain)

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

# Contoh pemakaian
file_path = "list_domain.csv"  # Nama file CSV yang berisi daftar domain
check_domains_from_csv(file_path)