function Set-ComputerSleepTimeout {
    param(
        [int]$MinutesIdleBeforeSleep
    )
    try {
        # Mengkonversi menit ke detik
        $idleTimeoutInSeconds = $MinutesIdleBeforeSleep * 60

        # Mendapatkan GUID dari active power plan
        $activePowerPlanGuid = (powercfg -getactivescheme).Split(' ')[3]

        # Mengatur idle timeout untuk sleep pada AC power (plugged in) dan battery
        powercfg -setacvalueindex $activePowerPlanGuid SUB_SLEEP STANDBYIDLE $idleTimeoutInSeconds
        powercfg -setdcvalueindex $activePowerPlanGuid SUB_SLEEP STANDBYIDLE $idleTimeoutInSeconds

        # Apply settings
        powercfg -SetActive $activePowerPlanGuid

        "Command Success: Set-ComputerSleepTimeout to $MinutesIdleBeforeSleep minutes." | Out-File -Append -FilePath "PowerPlanSettingsLog.txt"
    } catch {
        "Command Failed: $_" | Out-File -Append -FilePath "PowerPlanSettingsLog.txt"
    }
}

function Enable-RequirePasswordOnWake {
    try {
        # Mendapatkan GUID dari active power plan
        $activePowerPlanGuid = (powercfg -getactivescheme).Split(' ')[3]

        # Mengatur agar Windows meminta password setelah wake up dari sleep pada AC power (plugged in) dan battery
        powercfg -setacvalueindex $activePowerPlanGuid SUB_NONE CONSOLELOCK 1
        powercfg -setdcvalueindex $activePowerPlanGuid SUB_NONE CONSOLELOCK 1

        # Apply settings
        powercfg -SetActive $activePowerPlanGuid

        "Command Success: Enable-RequirePasswordOnWake." | Out-File -Append -FilePath "PowerPlanSettingsLog.txt"
    } catch {
        "Command Failed: $_" | Out-File -Append -FilePath "PowerPlanSettingsLog.txt"
    }
}

# Contoh pemanggilan function
Set-ComputerSleepTimeout -MinutesIdleBeforeSleep 5
Enable-RequirePasswordOnWake
