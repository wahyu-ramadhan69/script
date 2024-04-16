function Set-ComputerSleepTimeout {
    param(
        [int]$MinutesIdleBeforeSleep
    )
    try {
        $idleTimeoutInSeconds = $MinutesIdleBeforeSleep * 60

        $activePowerPlanGuid = (powercfg -getactivescheme).Split(' ')[3]

        powercfg -setacvalueindex $activePowerPlanGuid SUB_SLEEP STANDBYIDLE $idleTimeoutInSeconds
        powercfg -setdcvalueindex $activePowerPlanGuid SUB_SLEEP STANDBYIDLE $idleTimeoutInSeconds

        powercfg -SetActive $activePowerPlanGuid

        "Command Success: Set-ComputerSleepTimeout to $MinutesIdleBeforeSleep minutes." | Out-File -Append -FilePath "PowerPlanSettingsLog.txt"
    } catch {
        "Command Failed: $_" | Out-File -Append -FilePath "PowerPlanSettingsLog.txt"
    }
}

function Enable-RequirePasswordOnWake {
    try {
        $activePowerPlanGuid = (powercfg -getactivescheme).Split(' ')[3]

        powercfg -setacvalueindex $activePowerPlanGuid SUB_NONE CONSOLELOCK 1
        powercfg -setdcvalueindex $activePowerPlanGuid SUB_NONE CONSOLELOCK 1

        powercfg -SetActive $activePowerPlanGuid

        "Command Success: Enable-RequirePasswordOnWake." | Out-File -Append -FilePath "PowerPlanSettingsLog.txt"
    } catch {
        "Command Failed: $_" | Out-File -Append -FilePath "PowerPlanSettingsLog.txt"
    }
}

Set-ComputerSleepTimeout -MinutesIdleBeforeSleep 5
Enable-RequirePasswordOnWake
