# Modules
if (-not $env:MY_MODULES_LOADED)
{
  $modules = @(
    @{ Name = "Terminal-Icons"; ConfigKey = "Terminal-Icons_installed" }
    #@{ Name = "CompletionPredictor"; ConfigKey = "CompletionPredictor_installed" },
    #@{ Name = "WindowsConsoleFonts"; ConfigKey = "WindowsConsoleFonts_installed" },
    #@{ Name = "Powershell-Yaml"; ConfigKey = "Powershell-Yaml_installed" },
    #@{ Name = "PoshFunctions"; ConfigKey = "PoshFunctions_installed" }
  )
  $importedModuleCount = 0
  foreach ($module in $modules)
  {

    $isImported = Get-Module -Name $module.Name -ErrorAction SilentlyContinue
    if ($isImported -ne "True")
    {
      Import-Module $module.Name
      $importedModuleCount++
    }
  }

  Write-Host "✅ Imported $importedModuleCount modules successfully." -ForegroundColor Green

  if (Get-Module -Name WindowsConsoleFonts -ErrorAction SilentlyContinue)
  {
    Set-ConsoleFont JetBrainsMono -Size 18
  }
} else
{
  $env:MY_MODULES_LOADED = $true
}
