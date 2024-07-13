# ReadLine
if (-not $env:MY_READLINE_CONFIG_LOADED)
{
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

  # PSFzf
  Set-PSFzfOption -PSReadLineChordProvider 'Ctrl+f' -PSReadLineChordReverseHistory 'Ctrl+r'

  Write-Host "✅ Loaded readline config successfully." -ForegroundColor Green
} else
{
  $env:MY_READLINE_CONFIG_LOADED = $true
}
