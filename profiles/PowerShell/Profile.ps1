# Show path to executable
$profilesRoot = Split-Path $Profile
. (Join-Path $profilesRoot "EnvVariables.ps1")
. (Join-Path $profilesRoot "Functions.ps1")
. (Join-Path $profilesRoot "Aliases.ps1")
. (Join-Path $profilesRoot "Modules.ps1")
. (Join-Path $profilesRoot "Readline.ps1")

Invoke-Expression (&starship init powershell)
Enable-TransientPrompt
Invoke-Expression (& { ( zoxide init powershell | Out-String ) })
