# Define log files with common prefix
$logFileExecutionPolicy = "$env:TEMP\STARTUP_SetExecutionPolicyLog.txt"
$logFileStartKanata = "$env:TEMP\STARTUP_StartKanataLog.txt"
$logFileStartTiling = "$env:TEMP\STARTUP_StartTilingLog.txt"

# $profilesRoot = Split-Path $Profile
# . (Join-Path $profilesRoot "Functions.ps1")

$logFile = $logFileExecutionPolicy
Add-Content -Path $logFile -Value "Setting Execution Policy at $(Get-Date)"
Set-ExecutionPolicy Unrestricted -Scope Process -Force | Out-Null
Add-Content -Path $logFile -Value "Execution Policy set at $(Get-Date)"

$logFile = $logFileStartKanata
Add-Content -Path $logFile -Value "Starting StartKanata at $(Get-Date)"
StartKanata | Out-File -Append -FilePath $logFile
Add-Content -Path $logFile -Value "StartKanata completed at $(Get-Date)"

$logFile = $logFileStartTiling
Add-Content -Path $logFile -Value "Starting StartTiling at $(Get-Date)"
StartTiling | Out-File -Append -FilePath $logFile
Add-Content -Path $logFile -Value "StartTiling completed at $(Get-Date)"

Get-Job | Wait-Job

Get-Job | Remove-Job
