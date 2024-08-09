# Env variables
if (-not $env:MY_ENV_VARS_LOADED)
{
  $env:YAZI_FILE_ONE = "$Env:Programfiles\Git\usr\bin\file.exe"
  $env:MYVIMRCLSP = "$env:LOCALAPPDATA/nvim/lua/initlsp.lua"
  $env:EDITOR = "nvim"
  $env:MY_DOTFILES_DIR = "~/windots"
  # Use pwsh if not using WSL
  $env:SHELL = "bash"

  $env:BINPATH="$env:USERPROFILE/.bin"
  # Adding binaries from BINPATH to path
  if ($env:Path -notlike "*$env:BINPATH*")
  {
    $env:Path += ";$env:BINPATH"
  }

  if ($env:Path -notlike "*$($env:USERPROFILE)\scoop\shims*")
  {
    $env:Path += ";$env:USERPROFILE\scoop\shims"
  }

  if ($env:Path -notlike "*$($env:USERPROFILE)\scoop\apps\mpv\current*")
  {
    $env:Path += ";$env:USERPROFILE\scoop\apps\mpv\current"
  }

  Write-Host "✅ Loaded env variables successfully." -ForegroundColor Green
} else
{
  $env:MY_ENV_VARS_LOADED = $true
}
