$confirmation = Read-Host "Want to install tools, pwsh modules and fonts? (Y/N)"

# Check user's response
if ($confirmation -eq "Y" -or $confirmation -eq "y") {
  # Scoop Packages
  scoop config aria2-warning-enabled false
  scoop bucket add anderlli0053_DEV-tools https://github.com/anderlli0053/DEV-tools
  scoop install neovim eza fd fzf ripgrep bat less gh git delta make gcc msys2 openssh wget curl nodejs python powershell powertoys winget 7zip gzip komorebi whkd oh-my-posh
  scoop install unar jq yq poppler zoxide yazi
  # This installation has file.exe, which will be used by yazi to display infomation about file
  winget install Git.Git

  scoop update *

  Install-Module -Name Terminal-Icons -Repository PSGallery -Force -AllowClobber
  Install-Module -Name PSReadLine -Force -SkipPublisherCheck -AllowClobber
  Install-Module -Name PSFzf -Force -AllowClobber
  Install-Module -Name CompletionPredictor -Repository PSGallery -Force -AllowClobber
  Install-Module -Name WindowsConsoleFonts -Force -AllowClobber

  Update-Module

  # Install Font
  # oh-my-posh font install FiraCode
  oh-my-posh font install JetBrainsMono

  # Install neovim helper
  pip install neovim
}
else {
    Write-Warning "Skipping Installation."
}

Write-Warning "Starting with config symlinking."

# Fetch submodules
# git config core.symlinks true
# git submodule update --init --recursive
rm dotfiles-open -Force -Recurse
rm ~/.config/git -Force -Recurse
# Clones the repo including private config
git clone --recurse-submodules -c core.symlinks=true https://github.com/guruor/dotfiles-open

function Create-Symlinks {
  param (
    [Parameter(Mandatory = $true)]
    [string]$SourceDirectory,
    [Parameter(Mandatory = $true)]
    [string]$DestinationDirectory,
    [Parameter(Mandatory = $false)]
    [switch]$DryRun = $true
  )

  Write-Warning "Symlinking files from '$SourceDirectory' to '$DestinationDirectory'."

  # Ensure source directory exists
  if (-not (Test-Path $SourceDirectory)) {
    Write-Error "Error: Source directory '$SourceDirectory' not found."
    return
  }

  # Get all files recursively (using Get-ChildItem with -File and -Recurse)
  $items = Get-ChildItem -Path $SourceDirectory -Recurse -File

  foreach ($item in $items) {
    $sourceItem = $item.FullName
    $relativePath = $item.FullName.Substring($SourceDirectory.Length).TrimStart('\')  # Get relative path
    
    # Handle empty relative path
    if ($relativePath -eq "") {
      $relativePath = "."
    }

    # Construct the destination item path with relative path
    $destinationItem = Join-Path -Path $DestinationDirectory -ChildPath $relativePath

    #  For DryRun, show intended action
    if ($DryRun) {
      Write-Output "Would create symbolic link: $destinationItem -> $sourceItem"
      continue
    }

    # Dry-run check skipped, proceed with actual creation

    # Create parent directories if they don't exist
    $parentDirectory = $destinationItem.Substring(0, $destinationItem.LastIndexOf('\'))
    if (-not (Test-Path $parentDirectory)) {
      New-Item -ItemType Directory -Path $parentDirectory -Force | Out-Null
    }

    # Create symbolic link only for files
    New-Item -ItemType SymbolicLink -Path $destinationItem -Target $sourceItem -Force | Out-Null
    Write-Output "Created symbolic link: $destinationItem -> $sourceItem"
  }
}

function New-SelectiveSymlinks {
  param (
    [Parameter(Mandatory = $true)]
    [string]$SourceDirectory,
    [Parameter(Mandatory = $true)]
    [string]$DestinationDirectory,
    [Parameter()]
    [string[]]$FileList,
    [Parameter(Mandatory = $false)]
    [switch]$DryRun = $false
  )

  # Ensure the destination directory exists (create parent directories)
  New-Item -ItemType Directory -Path $DestinationDirectory -Force | Out-Null

  # Push the source directory onto the location stack
  Push-Location $SourceDirectory

  # If no file list provided, call the existing function for all files
  if (-not $FileList) {
    Create-Symlinks -SourceDirectory $SourceDirectory -DestinationDirectory $DestinationDirectory -DryRun:$DryRun
    Pop-Location  # Pop back to original location
    return
  }

  # Call the function for each item in the list (relative paths)
  foreach ($item in $FileList) {
    $itemPath = Join-Path -Path $SourceDirectory -ChildPath $item  # Resolve relative path

    if (-not (Test-Path $itemPath)) {
      Write-Warning "Skipping '$item': Path not found within source directory."
      continue
    }

    $sourcePath = $itemPath
    $destinationPath = Join-Path -Path $DestinationDirectory -ChildPath $item

    Create-Symlinks -SourceDirectory $sourcePath -DestinationDirectory $destinationPath -DryRun:$DryRun
  }

  # Pop back to the original location (likely git root)
  Pop-Location
}

# Config
$winConfigSourcePath = Join-Path $PWD ".config"
$profileConfigSourcePath = Join-Path $PWD "profiles"
$startupConfigSourcePath = Join-Path $PWD "startup"
$configSourcePath = Join-Path $PWD "dotfiles-open\.config"
$privateConfigSourcePath = Join-Path $PWD "dotfiles-open\Private\.config"
$configDestinationPath = Join-Path $env:USERPROFILE ".config"

# Komorebi, wkhd etc
New-SelectiveSymlinks -SourceDirectory "$winConfigSourcePath" -DestinationDirectory "$configDestinationPath"

# PowerShell 7 profiles
New-SelectiveSymlinks -SourceDirectory "$profileConfigSourcePath" -DestinationDirectory "$env:USERPROFILE\Documents"

# Symlink items in dotfiles-open\.config to .config in home directory
$fileList = @("kanata", "git")
New-SelectiveSymlinks -SourceDirectory "$configSourcePath" -DestinationDirectory "$configDestinationPath" -FileList @($fileList)

# Symlinking kanata-tray config
$fileList = @("kanata-tray", "yazi")
New-SelectiveSymlinks -SourceDirectory "$configSourcePath" -DestinationDirectory "$env:APPDATA" -FileList @($fileList)

# Symlinking nvim config
# New-Item -ItemType SymbolicLink -Target "$configSourcePath\nvim" -Path "$env:LOCALAPPDATA\nvim" -Force
$fileList = @("nvim")
New-SelectiveSymlinks -SourceDirectory "$configSourcePath" -DestinationDirectory "$env:LOCALAPPDATA" -FileList @($fileList)

# Symlinking ssh config
$fileList = @(".ssh")
rm "$env:USERPROFILE\.ssh" -Force -Recurse
New-SelectiveSymlinks -SourceDirectory "$privateConfigSourcePath" -DestinationDirectory "$env:USERPROFILE" -FileList @($fileList)

# Startup
New-SelectiveSymlinks -SourceDirectory "$startupConfigSourcePath" -DestinationDirectory "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"