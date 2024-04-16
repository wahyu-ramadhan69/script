# Mengatur idle time sebelum komputer sleep dan turn off the display
$minutesToSleep = 5
$minutesToTurnOffDisplay = 5

$idleTimeoutSleep = $minutesToSleep * 60
$idleTimeoutDisplay = $minutesToTurnOffDisplay * 60

try {
    $guid = (powercfg -getactivescheme).Split(' ')[3]

    powercfg -setacvalueindex $guid SUB_SLEEP STANDBYIDLE $idleTimeoutSleep
    powercfg -setdcvalueindex $guid SUB_SLEEP STANDBYIDLE $idleTimeoutSleep

    powercfg -setacvalueindex $guid SUB_VIDEO VIDEOIDLE $idleTimeoutDisplay
    powercfg -setdcvalueindex $guid SUB_VIDEO VIDEOIDLE $idleTimeoutDisplay

    powercfg -SetActive $guid

    powercfg -setacvalueindex $guid SUB_NONE CONSOLELOCK 1
    powercfg -setdcvalueindex $guid SUB_NONE CONSOLELOCK 1

    powercfg -SetActive $guid

    $successMessage = "Command Success: Sleep settings, display turn off settings, and password on wake have been configured."
    $successMessage | Out-File -Append -FilePath "PowerPlanSettingsLog.txt"
    Write-Output $successMessage
} catch {
    $errorMessage = "Command Failed: $_"
    Write-Output $errorMessage
}
