# Ambang batas hari untuk sertifikat yang akan kadaluarsa
$expiringSoonThreshold = 30
$today = Get-Date

# Jalankan certutil dan ambil informasi yang diperlukan
$output = certutil -view -out "RequestID,Certificate Template,NotAfter" 2>&1

# Memproses output dari certutil
$output | ForEach-Object {
    if ($_ -match "Row") {
        $requestID = $null
        $templateName = $null
        $notAfter = $null
    } elseif ($_ -match "RequestID:") {
        $requestID = $_.Split(":")[1].Trim()
    } elseif ($_ -match "Certificate Template:") {
        $templateName = $_.Split(":")[1].Trim()
    } elseif ($_ -match "NotAfter:") {
        $notAfterString = $_.Split(":")[1].Trim()
        $notAfter = [datetime]::ParseExact($notAfterString, 'M/d/yyyy h:mm tt', $null)
        $daysUntilExpiry = ($notAfter - $today).Days
        if ($daysUntilExpiry -le $expiringSoonThreshold) {
            # Template notifikasi
            $message = "Certificate with RequestID $requestID (Template: $templateName) will expire in $daysUntilExpiry day(s)."
            # Menampilkan pesan di terminal
            Write-Host $message
            # Konfigurasi parameter email
            $emailParams = @{
                To = "recipient@example.com"
                From = "sender@example.com"
                Subject = "Certificate Expiry Warning"
                Body = $message
                SmtpServer = "smtp.example.com"
            }
            # Kirim email notifikasi
            #Send-MailMessage @emailParams
        }
    }
}
