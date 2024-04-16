# Inisialisasi variabel untuk menyimpan output
$outputText = ""

$stores = @('My', 'Root', 'CA', 'AuthRoot')
$locations = @('LocalMachine', 'CurrentUser')

foreach ($location in $locations) {
    foreach ($storeName in $stores) {
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($storeName, $location)
        $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)
        $certs = $store.Certificates | Where-Object { $_.NotAfter -lt (Get-Date).AddDays(30) }

        foreach ($cert in $certs) {
            $daysRemaining = ($cert.NotAfter - (Get-Date)).Days
            $subjectName = $cert.SubjectName.Name
            $outputText += "Lokasi: $location - Store: $storeName - Sertifikat: $subjectName akan kedaluwarsa dalam $daysRemaining hari`n"
        }

        $store.Close()
    }
}

if (-not [string]::IsNullOrWhiteSpace($outputText)) {
    $outputPath = "C:\path\to\certificate_expiration_report.txt"
    $outputText | Out-File -FilePath $outputPath -Encoding UTF8

    $smtpServer = "mail.abc.id"
    $from = "anonymous@abc.id"
    $to = "recipient-email@abc.id"
    $subject = "Certificate Expiration Report"
    $body = "Berikut adalah laporan sertifikat yang akan kedaluwarsa dalam 30 hari ke depan."

    Send-MailMessage -SmtpServer $smtpServer -From $from -To $to -Subject $subject -Body $body -Attachments $outputPath -Port 25

    Remove-Item -Path $outputPath

    Write-Host "Laporan sertifikat telah dikirim dan file laporan telah dihapus."
} else {
    Write-Host "Tidak ada sertifikat yang akan kedaluwarsa dalam 30 hari ke depan. Tidak mengirim email."
}
