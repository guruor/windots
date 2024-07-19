# Functions
if (-not $env:MY_FUNCTIONS_LOADED)
{
  function which ($command)
  {
    Get-Command -Name $command -ErrorAction SilentlyContinue |
      Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
  }

  function Show-NotificationToast
  {
    param(
      [string]$BalloonTipTitle = "Notification",
      [string]$BalloonTipText = "Default notification text.",
      [int]$Duration = 3000
    )

    Add-Type -AssemblyName System.Windows.Forms

    $NotifyIcon = New-Object System.Windows.Forms.NotifyIcon
    $NotifyIcon.Icon = [System.Drawing.SystemIcons]::$Icon
    $NotifyIcon.BalloonTipIcon = "Info"
    $NotifyIcon.BalloonTipTitle = $BalloonTipTitle
    $NotifyIcon.BalloonTipText = $BalloonTipText
    $NotifyIcon.Visible = $true

    $NotifyIcon.ShowBalloonTip($Duration)

    Start-Sleep -Milliseconds $Duration

    # Clean up the NotifyIcon object
    $NotifyIcon.Dispose()
  }

  function Switch-Shell ()
  {
    if ($env:SHELL -eq 'bash')
    {
      $env:SHELL='pwsh'
    } else
    {
      $env:SHELL='bash'
    }
    Show-NotificationToast -BalloonTipText "Switched the SHELL to $env:SHELL" -Duration 3000
  }

  function openterm
  {
    [CmdletBinding()]
    param(
      [string]$title,
      [string]$cmdStr,
      [string]$shell = "$env:SHELL",
      [string]$workingDirectory = "$env:USERPROFILE"
    )

    $terminal = "alacritty"

    # Handling WSL commands
    if ("$env:SHELL" -eq "bash")
    {
      if (-not $cmdStr)
      {
        $cmdStr = "cd; cd; zsh --login -i"
      } else
      {
        $cmdStr = "cd; cd; zsh --login -ic '$cmdStr'"
      }
    }

    if ("$env:SHELL" -eq "pwsh")
    {
      if (-not $cmdStr)
      {
        $cmdStr = "$env:SHELL"
      }
    }

    # Check if specified terminal executable exists
    switch ($terminal)
    {
      "alacritty"
      {
        Start-Process -FilePath alacritty -ArgumentList "--title ""$title"" --working-directory ""$workingDirectory"" -e ""$shell"" -c ""$cmdStr"""
      }
      default
      {
        Write-Warning "Unsupported terminal: $terminal"
        return
      }
    }
  }

  Write-Host "✅ Loaded functions successfully." -ForegroundColor Green
} else
{
  $env:MY_FUNCTIONS_LOADED = $true
}
