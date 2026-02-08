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
    param ([Parameter(Mandatory=$true)]$SourcePath, [Parameter(Mandatory=$true)]$DestinationPath, [string[]]$FileList = @())

    if (-not (Test-Path $SourcePath)) { return }

    $items = if ($FileList.Count -gt 0) {
        $FileList | ForEach-Object { Get-Item (Join-Path $SourcePath $_) -ErrorAction SilentlyContinue }
    } else {
        Get-ChildItem -Path $SourcePath -Recurse -File
    }

    foreach ($item in $items) {
        $relativePath = if ($item.PSIsContainer) { $item.Name } else { $item.FullName.Substring($SourcePath.Length).TrimStart('\') }
        $dest = Join-Path $DestinationPath $relativePath
        $parent = Split-Path $dest
        
        if (-not (Test-Path $parent)) { New-Item -ItemType Directory $parent -Force | Out-Null }
        if (Test-Path $dest) { Remove-Item $dest -Force -Recurse -ErrorAction SilentlyContinue }
        
        try {
            New-Item -ItemType SymbolicLink -Path $dest -Target $item.FullName -Force -ErrorAction Stop | Out-Null
            Write-Host "Linked (Native): $relativePath" -ForegroundColor Gray
        } catch {
            $flag = if ($item.PSIsContainer) { "/D" } else { "" }
            cmd /c mklink $flag "$dest" "$($item.FullName)" | Out-Null
            Write-Host "Linked (mklink): $relativePath" -ForegroundColor Gray
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
        # Only install if not already found
        winget install --id $app --silent --no-upgrade -e
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

    # Python helpers (pip handles this internally)
    pip install neovim git+https://github.com/mps-youtube/yewtube.git --quiet

    # Refresh Environment
    $env:PATH = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# --- 3. Symlinking Block ---
Write-Warning "Starting with config symlinking."
$configDest = Join-Path $HOME ".config"
$dotOpen = Join-Path $PWD "dotfiles-open"

New-Symlinks -SourcePath "$PWD\.config" -DestinationPath $configDest
New-Symlinks -SourcePath "$dotOpen\.config" -DestinationPath $configDest -FileList @("kanata", "git", "wezterm")
New-Symlinks -SourcePath "$dotOpen\.config" -DestinationPath $env:APPDATA -FileList @("kanata-tray", "yazi", "bottom", "alacritty", "espanso", "nushell")
New-Symlinks -SourcePath "$dotOpen\.config" -DestinationPath $env:LOCALAPPDATA -FileList @("nvim")
New-Symlinks -SourcePath "$dotOpen\Private\.config" -DestinationPath $HOME -FileList @(".ssh")
New-Symlinks -SourcePath "$PWD\profiles" -DestinationPath "$HOME\Documents"

# Legacy PowerShell Profile Link
$pwshPath = Join-Path $HOME "Documents\WindowsPowerShell"
if (Test-Path "$PWD\profiles\PowerShell") {
    if (Test-Path $pwshPath) { Remove-Item $pwshPath -Force -Recurse -ErrorAction SilentlyContinue }
    cmd /c mklink /D "$pwshPath" "$PWD\profiles\PowerShell"
}

New-Symlinks -SourcePath "$PWD\startup" -DestinationPath "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"

# --- 4. Post-Install ---
if (Get-Process -Name "kanata-tray" -ErrorAction SilentlyContinue) {
    Write-Host "Kanata-tray is already running." -ForegroundColor Green
} elseif (Test-Path "$HOME/.bin/kanata-tray.exe") {
    Write-Host "Launching Kanata-Tray..." -ForegroundColor Cyan
    Start-Process "$HOME/.bin/kanata-tray.exe"
}

Write-Host "Setup Complete!" -ForegroundColor Green
