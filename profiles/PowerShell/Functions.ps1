# Functions
if (-not $env:MY_FUNCTIONS_LOADED)
{
  function which ($command)
  {
    Get-Command -Name $command -ErrorAction SilentlyContinue |
      Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
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
         $cmdStr = "sleep 0.1; cd; zsh --login -i"
      } else {
        $cmdStr = "sleep 0.1; cd; zsh --login -ic '$cmdStr'"
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
