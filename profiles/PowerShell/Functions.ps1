# Functions
if (-not $env:MY_FUNCTIONS_LOADED)
{
  function which ($command)
  {
    Get-Command -Name $command -ErrorAction SilentlyContinue |
      Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
  }

  function Download-GithubRelease
  {
    param (
      [string]$repo
    )

    # Fetch the latest release data from the GitHub API
    $releaseData = curl -ks "https://api.github.com/repos/$repo/releases/latest" | ConvertFrom-Json

    # Extract all download URLs with a .exe extension
    $urls = $releaseData.assets | Where-Object { $_.browser_download_url -like "*.exe" } | Select-Object -ExpandProperty browser_download_url

    # Use fzf to select the desired executable to download
    $url = $urls | fzf --height 40% --border --header "Select the executable to download"

    if ($url)
    {
      # Extract the filename from the URL
      $filename = [System.IO.Path]::GetFileName($url)

      # Download the selected executable
      curl -kOL $url

      Write-Host "Downloaded $filename"
    } else
    {
      Write-Host "No executable selected."
    }
  }

  function Restart-WHKD
  {
    taskkill /f /im whkd.exe
    # if shell is pwsh / powershell
    Start-Process whkd -WindowStyle hidden
    # if shell is cmd
    #start /b whkd
    Show-NotificationToast -BalloonTipText "Restarted WHKD" -Duration 1000
  }

  function Reload-Komorebi
  {
    komorebic reload-configuration
    Show-NotificationToast -BalloonTipText "Restarted Komorebi" -Duration 1000
  }

  function Show-NotificationToast
  {
    param(
      [string]$BalloonTipTitle = "Notification",
      [string]$BalloonTipText = "Default notification text.",
      [int]$Duration = 3000
    )
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    $NotifyIcon = New-Object System.Windows.Forms.NotifyIcon
    $NotifyIcon.Icon = [System.Drawing.SystemIcons]::Information
    $NotifyIcon.BalloonTipIcon = "Info"
    $NotifyIcon.BalloonTipTitle = $BalloonTipTitle
    $NotifyIcon.BalloonTipText = $BalloonTipText
    $NotifyIcon.Visible = $True
    $NotifyIcon.ShowBalloonTip($Duration)
    Start-Sleep -Milliseconds $Duration
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

    # Check if specified terminal executable exists
    switch ($terminal)
    {
      "alacritty"
      {
        $arguments = "--title ""$title"" --working-directory ""$workingDirectory"" -e ""$shell"""
        if ($cmdStr) {
            $arguments += " -c ""$cmdStr"""
        }

        Start-Process -FilePath $terminal -ArgumentList $arguments
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
