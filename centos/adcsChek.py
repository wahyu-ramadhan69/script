import datetime

# Fungsi untuk membaca data dari file teks dan mengembalikan daftar baris
def read_data_from_file(filename):
    with open(filename, 'r') as file:
        data = file.readlines()
    return data

# Fungsi untuk mengambil informasi dari baris data
def parse_data(data):
    parsed_data = []
    parsed_row = {}  # Inisialisasi dictionary untuk menyimpan baris yang sedang di-parse
    for line in data:
        if line.strip():  # Memastikan baris tidak kosong
            if line.startswith('Row'):  # Mengabaikan baris yang berisi judul kolom dan skema
                parsed_row = {}  # Me-reset dictionary saat mulai membaca baris baru
            else:
                # Memeriksa apakah baris memiliki karakter pembatas ':'
                if ':' in line:
                    key, value = line.split(':', 1)  # Membagi baris menjadi kunci (key) dan nilai (value)
                    parsed_row[key.strip()] = value.strip().strip('"')
                    if key.strip() == 'NotAfter':  # Mengubah format tanggal ke format yang dapat diurutkan
                        parsed_row[key.strip()] = datetime.datetime.strptime(parsed_row[key.strip()], '%m/%d/%Y %I:%M %p')
                        # %m = bulan, %d = hari, %Y = tahun, %I = jam, %M = menit, %p = AM/PM
            if len(parsed_row) == 4:  # Baris telah di-parse sepenuhnya
                parsed_data.append(parsed_row)
    return parsed_data

# Fungsi untuk menemukan sertifikat yang sudah kadaluwarsa
def find_expired_certificates(data):
    current_datetime = datetime.datetime.now()
    expired_certificates = []
    for row in data:
        if row['NotAfter'] < current_datetime:
            expired_certificates.append(row)
    return expired_certificates

# Memanggil fungsi untuk membaca data dari file tes.txt
filename = 'tes.txt'
data = read_data_from_file(filename)

# Memanggil fungsi untuk mengambil informasi dari baris data
parsed_data = parse_data(data)

# Memanggil fungsi untuk menemukan sertifikat yang sudah kadaluwarsa
expired_certificates = find_expired_certificates(parsed_data)

# Menampilkan sertifikat yang sudah kadaluwarsa
print("Sertifikat yang sudah kadaluwarsa:")
for certificate in expired_certificates:
    print(certificate)
