# Mengatur store sertifikat yang akan diperiksa
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store("My", "LocalMachine")
$store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)

# Mendapatkan tanggal saat ini
$now = Get-Date

# Menyaring sertifikat kadaluarsa
$expiredCerts = $store.Certificates | Where-Object { $_.NotAfter -lt $now }

# Menghapus sertifikat kadaluarsa
foreach ($cert in $expiredCerts) {
    Write-Output "Menghapus sertifikat kadaluarsa: $($cert.Subject)"
    # $store.Remove($cert)
}

# Menutup store
$store.Close()