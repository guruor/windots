# Functions
if (-not $env:MY_FUNCTIONS_LOADED)
{
  function which ($command)
  {
    Get-Command -Name $command -ErrorAction SilentlyContinue |
      Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
  }

  Write-Host "✅ Loaded functions successfully." -ForegroundColor Green
} else
{
  $env:MY_FUNCTIONS_LOADED = $true
}
