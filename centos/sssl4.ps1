# Konfigurasi server SMTP dan detil email
$smtpServer = "smtp.gmail.com"
$from = "it_infra@bcaf.id"
$to = "it_infra@bcaf.id"
$subject = "Expired Certificates Report - $(Get-Date -Format 'MM/dd/yyyy')"
$body = @"
Dear Team,

Please find attached the expired certificates report as of $(Get-Date -Format 'MM/dd/yyyy'). This report includes details of all certificates that have expired up to the current date and requires your attention.

We recommend reviewing the attached report to ensure that necessary actions can be taken to update or renew these certificates as needed. Timely management of these certificates is crucial for maintaining our system's security and functionality.

Thank you for your attention to this matter.

Best regards,

[Your Name]
IT Infrastructure Team
"@

$password = "cpeyqoewqmrxuvsn" # Ganti dengan App Password yang dihasilkan dari akun Google Anda

$scriptPath = [Environment]::GetFolderPath("Desktop")
Set-Location $scriptPath

$output = certutil -view -out "RequestID,RequesterName,CommonName,NotAfter"
$certificates = @()
$now = Get-Date
$reportLines = @("Expired Certificates Report:`r`n")

# Parsing output disesuaikan

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
            $reportLines += "RequestId: $($requestId), RequesterName: $($requesterName), Common Name: $($commonName), Expired On: $($notAfter.ToString('MM/dd/yyyy h:mm tt'))`r`n"
        }
    }
}

$reportFileName = "$scriptPath\ExpiredCertificatesReport.txt"
$reportLines | Out-File -FilePath $reportFileName

if (Test-Path $reportFileName) {
    $smtpClient = New-Object Net.Mail.SmtpClient($smtpServer, 587)
    $smtpClient.EnableSsl = $true
    $smtpClient.Credentials = New-Object System.Net.NetworkCredential($from, $password)
    $message = New-Object Net.Mail.MailMessage($from, $to, $subject, $body)
    $attachment = New-Object System.Net.Mail.Attachment($reportFileName)
    $message.Attachments.Add($attachment)

    try {
        $smtpClient.Send($message)
        Write-Output "Email sent successfully."
    } catch {
        Write-Output "Failed to send email: $_"
    } finally {
        $attachment.Dispose()
        $message.Attachments.Clear()
        $message.Dispose()
        $smtpClient.Dispose()

        # Tunggu hingga file benar-benar dilepaskan
        Start-Sleep -Seconds 2
        try {
            Remove-Item $reportFileName -Force
            Write-Output "Report file deleted."
        } catch {
            Write-Output "Failed to delete the report file: $_. Retrying..."
            Start-Sleep -Seconds 2
            Remove-Item $reportFileName -Force
        }
    }
} else {
    Write-Output "Report file not found: $reportFileName"
}
