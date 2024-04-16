# Konfigurasi server SMTP dan detil email
$smtpServer = "mail.bcaf.co.id"
$from = "NotificationADCS@bcaf.co.id"
$to = "20220662@bcaf.co.id"
$subject = "Expired Certificates Report"
$body = "Attached is the report on expired certificates."

$output = certutil -view -out "RequestID,RequesterName,CommonName,NotAfter"
# Inisialisasi variabel untuk parsing output
$certificates = @()
$now = Get-Date
# Parsing output
foreach ($line in $output -split "\r?\n") {
    if ($line -match "Row \d+:") {
        $requestId = $requesterName = $commonName = $notAfter = $null
    }
    if ($line -match "Issued Request ID:\s+0x([a-fA-F0-9]+)") {
        $requestId = $matches[1]
    } elseif ($line -match "Requester Name:\s+""(.*)""") {
        $requesterName = $matches[1]
    } elseif ($line -match "Issued Common Name:\s+""(.*)""") {
        $commonName = $matches[1]
    } elseif ($line -match "Certificate Expiration Date:\s+(.*)") {
        $notAfter = [DateTime]::ParseExact($matches[1], "M/d/yyyy h:mm tt", $null)
        if ($notAfter -lt $now) {
            $certificates += [PSCustomObject]@{
                RequestId = $requestId
                RequesterName = $requesterName
                CommonName = $commonName
                NotAfter = $notAfter
            }
        }
    }
}
# Check apakah ada sertifikat yang kedaluwarsa
if ($certificates.Count -eq 0) {
    Write-Output "No expired certificates found."
    exit
}
# Menyiapkan laporan untuk sertifikat yang kedaluwarsa
$reportLines = @("Expired Certificates Report:`r`n")
foreach ($cert in $certificates) {
    $reportLines += "RequestId: $($cert.RequestId), RequesterName: $($cert.RequesterName), CommonName: $($cert.CommonName), Expired On: $($cert.NotAfter.ToString('MM/dd/yyyy h:mm tt'))`r`n"
}
# Simpan laporan ke file
$reportFileName = "ExpiredCertificatesReport.txt"
$reportLines | Out-File -FilePath $reportFileName
Write-Output "Report generated: $reportFileName"

# Kirim email dengan laporan sebagai lampiran
Send-MailMessage -SmtpServer $smtpServer -From $from -To $to -Subject $subject -Body $body -Attachment $reportFileName -Port 25
