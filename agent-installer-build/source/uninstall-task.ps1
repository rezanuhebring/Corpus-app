# Task Details
$TaskName = "CorpusAgentService"

# Check if the task exists and unregister it
$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($task) {
    Write-Host "Unregistering scheduled task: $TaskName"
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Task uninstalled successfully."
} else {
    Write-Host "Task not found. Nothing to do."
}