# Set lokasi file CSV
$csvPath = "D:\certi.csv"

# Baca data dari CSV
$certificates = Import-Csv -Path $csvPath

# Dapatkan tanggal saat ini
$today = Get-Date

# Iterasi melalui setiap sertifikat
foreach ($cert in $certificates) {
    # Konversi string tanggal kedaluwarsa ke tipe DateTime
    $expirationDate = [DateTime]::ParseExact($cert.NotAfter, "M/d/yyyy h:mm tt", $null)
    
    # Hitung selisih hari antara tanggal kedaluwarsa dengan hari ini
    $daysUntilExpiration = ($expirationDate - $today).Days
    
    # Cek jika sertifikat akan kadaluarsa dalam 30 hari ke depan
    if ($daysUntilExpiration -le 30 -and $daysUntilExpiration -gt 0) {
        Write-Output "Sertifikat `"$($cert.CommonName)`" akan kadaluarsa dalam $daysUntilExpiration hari."
    }
    # Cek jika sertifikat sudah kedaluwarsa
    elseif ($daysUntilExpiration -le 0) {
        Write-Output "Sertifikat `"$($cert.CommonName)`" dengan nama kadaluarsa."
    }
}
