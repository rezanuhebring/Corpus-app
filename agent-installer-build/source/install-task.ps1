param(
    [string]$InstallPath,
    [string]$ScheduleType # New parameter: e.g., "Startup", "Daily", "Hourly"
)

# Task Details
$TaskName = "CorpusAgentService"
$TaskDescription = "Monitors document folders and sends them to the Corpus server. (Installed by Corpus)"
$PythonExe = Join-Path $InstallPath "pythonw.exe" # Use pythonw.exe to run without a console window
$AgentScript = Join-Path $InstallPath "agent.py"

# Action to run the agent
$Action = New-ScheduledTaskAction -Execute $PythonExe -Argument $AgentScript -WorkingDirectory $InstallPath

# --- DYNAMIC TRIGGER CREATION ---
$Trigger = $null
switch ($ScheduleType) {
    "Startup" {
        # Trigger to run at system startup
        $Trigger = New-ScheduledTaskTrigger -AtStartup
        break
    }
    "Daily" {
        # Trigger to run once a day at a specific time (e.g., 3:00 AM)
        $Trigger = New-ScheduledTaskTrigger -Daily -At 3am
        break
    }
    "Hourly" {
        # Trigger to run, and then repeat every hour indefinitely
        $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration ([System.TimeSpan]::MaxValue)
        break
    }
    default {
        # Default to startup if an unknown value is passed
        Write-Warning "Unknown schedule type '$ScheduleType'. Defaulting to run at startup."
        $Trigger = New-ScheduledTaskTrigger -AtStartup
    }
}

# Principal to run as the logged-on user. This is often better than SYSTEM
# as it ensures access to the user's documents and network drives.
$Principal = New-ScheduledTaskPrincipal -UserId (Get-CimInstance Win32_ComputerSystem).UserName -LogonType Interactive

# Settings for the task
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit "PT0" -MultipleInstances IgnoreNew

# Unregister any old version of the task first, just in case
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

# Register the new task
Write-Host "Registering scheduled task: $TaskName with schedule: $ScheduleType"
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Description $TaskDescription -Force

Write-Host "Task installed successfully."