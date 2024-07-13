# File for Current User, All Hosts - $PROFILE.CurrentUserAllHosts

if (-not $env:MY_ALIASES_LOADED)
{
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

  Write-Host "✅ Loaded aliases successfully." -ForegroundColor Green
} else
{
  $env:MY_ALIASES_LOADED = $true
}


