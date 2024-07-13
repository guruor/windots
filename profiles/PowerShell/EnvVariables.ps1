# Env variables
if (-not $env:MY_ENV_VARS_LOADED)
{
  $env:YAZI_FILE_ONE = "$Env:Programfiles\Git\usr\bin\file.exe"
  $env:MYVIMRCLSP = "$env:LOCALAPPDATA/nvim/lua/initlsp.lua"
  $env:EDITOR = "nvim"
  $env:MY_DOTFILES_DIR = "~/windots"
  $env:SHELL = "pwsh"

  Write-Host "✅ Loaded env variables successfully." -ForegroundColor Green
} else
{
  $env:MY_ENV_VARS_LOADED = $true
}
