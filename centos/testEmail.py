import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# Pengaturan server SMTP lokal dan port
smtp_server = 'mail.bcaf.co.id'
smtp_port = 25  # Port default untuk SMTP tanpa enkripsi

# Membuat pesan email
msg = MIMEMultipart()
msg['From'] = 'backupexec@bcaf.co.id'
msg['To'] = '20230493@bcaf.co.id'
msg['Subject'] = 'Subjek Email Tanpa Password'
body = 'Ini adalah isi email yang dikirim tanpa menggunakan password.'
msg.attach(MIMEText(body, 'plain'))

# Mengirim email
try:
    with smtplib.SMTP(smtp_server, smtp_port) as server:
        server.sendmail(msg['From'], msg['To'], msg.as_string())
        print("Email berhasil dikirim!")
except Exception as e:
    print(f"Gagal mengirim email: {e}")

sertifikart ada di adcs