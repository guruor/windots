# --- 1. Helper Functions ---

function Install-GithubRelease {
    param([string]$repo, [string]$destination)
    Write-Host "Checking release for ${repo}..." -ForegroundColor Cyan
    
    $procName = [System.IO.Path]::GetFileNameWithoutExtension($destination)
    if (Get-Process -Name $procName -ErrorAction SilentlyContinue) {
        Stop-Process -Name $procName -Force
    }

    $destDir = Split-Path $destination
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory $destDir -Force | Out-Null }
    
    # Clean up accidental directories from previous runs
    if (Test-Path $destination -PathType Container) {
        Remove-Item $destination -Recurse -Force -ErrorAction SilentlyContinue
    }

    $api = "https://api.github.com/repos/$repo/releases/latest"
    try {
        $response = Invoke-RestMethod -Uri $api
        $asset = $response.assets | Where-Object { $_.name -like "*win*" -or $_.name -like "*64*" -or $_.name -like "*.exe" } | Select-Object -First 1
        
        $tempZip = Join-Path $env:TEMP $asset.name
        $extractPath = Join-Path $env:TEMP "gh_extract_$(Get-Random)"
        
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tempZip
        
        if ($tempZip -match "\.zip$") {
            Expand-Archive -Path $tempZip -DestinationPath $extractPath -Force
            $actualExe = Get-ChildItem -Path $extractPath -Filter "*.exe" -Recurse | Select-Object -First 1
            if ($actualExe) { Move-Item $actualExe.FullName $destination -Force }
        } else {
            Move-Item $tempZip $destination -Force
        }
        Remove-Item $tempZip, $extractPath -Recurse -ErrorAction SilentlyContinue
        Write-Host "Successfully installed ${repo}." -ForegroundColor Green
    } catch {
        Write-Error "Failed to install ${repo}: $($_.Exception.Message)"
    }
}

function New-Symlinks {
    param (
        [Parameter(Mandatory=$true)][string]$SourcePath, 
        [Parameter(Mandatory=$true)][string]$DestinationPath, 
        [string[]]$FileList = @()
    )

    if (-not (Test-Path $SourcePath)) { return }

    # FIX: Remove -Recurse. Only look at top-level items.
    $items = if ($FileList.Count -gt 0) {
        $FileList | ForEach-Object { Get-Item (Join-Path $SourcePath $_) -ErrorAction SilentlyContinue }
    } else {
        Get-ChildItem -Path $SourcePath | Where-Object { $_.Attributes -notlike "*ReparsePoint*" }
    }

    foreach ($item in $items) {
        $sourceFullName = $item.FullName
        $dest = Join-Path $DestinationPath $item.Name
        
        # Safety Check: Never link a file to itself
        if ($sourceFullName -eq $dest) { continue }

        # Ensure Destination Parent exists
        if (-not (Test-Path $DestinationPath)) { 
            New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null 
        }
        
        # Remove existing destination (file or folder symlink)
        if (Test-Path $dest) { 
            Remove-Item $dest -Force -Recurse -ErrorAction SilentlyContinue 
        }
        
        try {
            $type = if ($item.PSIsContainer) { "SymbolicLink" } else { "File" }
            # For folders, we must specify the type explicitly for Windows
            if ($item.PSIsContainer) {
                cmd /c mklink /D "$dest" "$sourceFullName" | Out-Null
            } else {
                New-Item -ItemType SymbolicLink -Path $dest -Target $sourceFullName -Force -ErrorAction Stop | Out-Null
            }
            Write-Host "Linked: $($item.Name)" -ForegroundColor Gray
        } catch {
            Write-Warning "Failed to link $($item.Name)"
        }
    }
}

# --- 2. Installation Block ---
$confirmation = Read-Host "Full Setup: Install tools, Rust, VS Build Tools, and Symlinks? (Y/N)"
if ($confirmation -match "^[Yy]") {
    
    # --- Visual Studio & C++ Build Tools ---
    # Check if MSVC compiler exists to avoid re-running the heavy installer
    if (-not (Get-Command "cl.exe" -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Visual Studio 2022 (This may take a while)..." -ForegroundColor Cyan
        # Using --no-upgrade to avoid getting stuck on existing installs
        winget install Microsoft.VisualStudio.2022.Community --silent --no-upgrade --override "--wait --quiet --add ProductLang En-us --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended"
        winget install Microsoft.VisualStudio.2022.BuildTools --silent --no-upgrade
    } else {
        Write-Host "Visual Studio/MSVC already detected. Skipping." -ForegroundColor Green
    }

    # --- Scoop Packages ---
    # Scoop naturally handles "already installed" by throwing a warning, which is fine.
    Write-Host "Updating/Installing Scoop packages..." -ForegroundColor Cyan
    scoop bucket add extras 2>$null
    scoop bucket add anderlli0053_DEV-tools https://github.com/anderlli0053/DEV-tools 2>$null
    scoop install git curl wget make msys2 7zip gzip unzip gcc nodejs python go rustup-msvc luarocks starship neovim eza fd fzf ripgrep bat less gh delta openssh powertoys winget komorebi whkd zoxide yazi unar jq yq poppler mpv yt-dlp ffmpeg

    # --- Winget Apps ---
    $wingetApps = @("Microsoft.Powershell", "Git.Git", "wez.wezterm", "Alacritty.Alacritty", "Ditto.Ditto", "Bitwarden.CLI", "Espanso.Espanso")
    foreach ($app in $wingetApps) {
        Write-Host "Checking $app..." -ForegroundColor Gray
        winget upgrade --id $app --silent --accept-source-agreements --accept-package-agreements -e
    }

    # --- Rust & Kanata ---
    if (-not (Get-Command "rustup" -ErrorAction SilentlyContinue)) {
        Write-Host "Initializing Rust..." -ForegroundColor Cyan
        rustup default stable
    }
    
    $env:PATH += ";$env:USERPROFILE\.cargo\bin"
    if (-not (Get-Command "kanata" -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Kanata via Cargo..." -ForegroundColor Cyan
        cargo install kanata
    }

    # --- Github Releases & Modules ---
    if (-not (Test-Path "$HOME/.bin/kanata-tray.exe")) {
        Install-GithubRelease -repo "rszyma/kanata-tray" -destination "$HOME/.bin/kanata-tray.exe"
    }

    # PowerShell Modules: Install-Module handles "already installed" if we don't use -Force
    $modules = @("Terminal-Icons", "PSReadLine", "PSFzf", "CompletionPredictor", "WindowsConsoleFonts")
    foreach ($mod in $modules) { 
        if (-not (Get-Module -ListAvailable -Name $mod)) {
            Install-Module $mod -Scope CurrentUser -Force -AllowClobber -ErrorAction SilentlyContinue 
        }
    }

    # Dynamically find the Python Scripts path and add to current session PATH
    $pythonScripts = python -c "import site; import os; print(os.path.join(site.USER_BASE, 'Scripts'))"
    if ($env:PATH -notlike "*$pythonScripts*") {
        $env:PATH += ";$pythonScripts"
        # To make it permanent for future sessions:
        [Environment]::SetEnvironmentVariable("Path", $env:PATH + ";$pythonScripts", "User")
    }
    Write-Host "Upgrading pip..." -ForegroundColor Cyan
    python.exe -m pip install --upgrade pip --quiet
    # Python helpers (pip handles this internally)
    pip install neovim git+https://github.com/mps-youtube/yewtube.git --quiet --no-warn-script-location

    # Refresh Environment
    $env:PATH = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# --- 3. Symlinking Block ---
Write-Warning "Starting prioritized config symlinking."
$dotDir = "$HOME/windots"
$dotOpenDir = "$HOME/dotfiles-open"
$configSource = Join-Path $dotOpenDir ".config"
$configDest = Join-Path $HOME ".config"

# 1. Handle Special Windows Paths FIRST (AppData/Local)
# This prevents these specific folders from being caught in the generic ~/.config link later
New-Symlinks -SourcePath $configSource -DestinationPath $env:APPDATA -FileList @("kanata-tray", "yazi", "bottom", "alacritty", "espanso", "nushell", "scoop")
New-Symlinks -SourcePath $configSource -DestinationPath $env:LOCALAPPDATA -FileList @("nvim")

# 2. CATCH-ALL: Link every remaining TOP-LEVEL folder/file in .config
# This will link ~/dotfiles-open/.config/git -> ~/.config/git (as a folder link)
Write-Host "Linking all top-level configs to $configDest..." -ForegroundColor Cyan
New-Symlinks -SourcePath $configSource -DestinationPath $configDest

# 3. PowerShell Profiles
$pwshPath = Join-Path $HOME "Documents\PowerShell"
# Points to the 'profiles' folder inside your dotfiles repo
if (Test-Path "$dotDir\profiles\PowerShell") {
    if (Test-Path $pwshPath) { Remove-Item $pwshPath -Force -Recurse -ErrorAction SilentlyContinue }
    New-Item -ItemType SymbolicLink -Path $pwshPath -Target "$dotDir\profiles\PowerShell" -Force | Out-Null
}

# 4. Windows Startup Folder
if (Test-Path "$dotDir\startup") {
    New-Symlinks -SourcePath "$dotDir\startup" -DestinationPath "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
}

# --- 4. Post-Install ---
if (Get-Process -Name "kanata-tray" -ErrorAction SilentlyContinue) {
    Write-Host "Kanata-tray is already running." -ForegroundColor Green
} elseif (Test-Path "$HOME/.bin/kanata-tray.exe") {
    Write-Host "Launching Kanata-Tray..." -ForegroundColor Cyan
    Start-Process "$HOME/.bin/kanata-tray.exe"
}

Write-Host "Setup Complete!" -ForegroundColor Green
