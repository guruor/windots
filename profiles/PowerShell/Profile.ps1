# File for Current User, All Hosts - $PROFILE.CurrentUserAllHosts
function New-Bash-Alias
{
  param (
    [string]$name,
    [string]$command
  )

  $aliasPath = "Function:\global:$name"

  # Check if the alias already exists
  if (-not (Test-Path $aliasPath))
  {
    $sb = [scriptblock]::Create($command)
    New-Item -Path $aliasPath -Value $sb | Out-Null
    # Write-Output "Alias '$name' created: $command"
  }
}

# Show path to executable
function which ($command)
{
  Get-Command -Name $command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

# Modules
Import-Module -Name CompletionPredictor
Import-Module -Name Terminal-Icons

# Windows terminal font
# Import-Module -Name WindowsConsoleFonts
# Set-ConsoleFont JetBrainsMono -Size 18

# Env variables
$env:YAZI_FILE_ONE = "$Env:Programfiles\Git\usr\bin\file.exe"
$env:MYVIMRCLSP = "$env:LOCALAPPDATA/nvim/lua/initlsp.lua"
$env:EDITOR = "nvim"
$env:MY_DOTFILES_DIR = "~/windots"
$env:SHELL = "pwsh"

# Aliases
Set-Alias vi nvim
New-Bash-Alias pwsha "start-process pwsh -verb runas"
New-Bash-Alias cf "cd ~/.config"
New-Bash-Alias dot "cd $env:MY_DOTFILES_DIR"
New-Bash-Alias udot "dot; cd dotfiles-open;"
New-Bash-Alias pdot "udot; cd Private;"
New-Bash-Alias doti "dot; . ./install"
New-Bash-Alias q "exit"
New-Bash-Alias .. "cd ../"
New-Bash-Alias c "nvim -u $env:MYVIMRCLSP @args"
New-Bash-Alias g "git @args"


# PSReadLine
Set-PSReadLineOption -EditMode vi
Set-PSReadLineKeyHandler -ViMode Insert -Chord Ctrl+h -Function BackwardDeleteChar
Set-PSReadLineKeyHandler -ViMode Insert -Chord Ctrl+w -Function BackwardKillWord
Set-PSReadLineKeyHandler -ViMode Insert -Chord Ctrl+k -Function KillLine
Set-PSReadlineKeyHandler -ViMode Insert -Chord Tab -Function MenuComplete
Set-PSReadLineKeyHandler -ViMode Insert -Chord Ctrl+p -Function HistorySearchBackward
Set-PSReadLineKeyHandler -ViMode Insert -Chord Ctrl+n -Function HistorySearchForward
Set-PSReadLineKeyHandler -Chord Ctrl-r -Function ReverseSearchHistory
Set-PSReadLineKeyHandler -Chord RightArrow -Function ForwardWord
Set-PSReadLineKeyHandler -Chord Tab -Function ForwardWord
Set-PSReadLineKeyHandler -Chord Ctrl+o -ScriptBlock {
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert('yazi')
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

# Readline prediction and completion
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -BellStyle None



Invoke-Expression (&starship init powershell)
Enable-TransientPrompt
Invoke-Expression (& { ( zoxide init powershell | Out-String ) })

# PSFzf
Set-PSFzfOption -PSReadLineChordProvider 'Ctrl+f' -PSReadLineChordReverseHistory 'Ctrl+r'
