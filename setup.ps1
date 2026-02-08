Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# 1. Install Scoop
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Scoop..." -ForegroundColor Cyan
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
}

# 2. Add Scoop to current session PATH immediately
$scoopPath = Join-Path $HOME "scoop\shims"
if ($env:PATH -notlike "*$scoopPath*") { $env:PATH += ";$scoopPath" }

# 3. Essential Bootstrap Tools
scoop install aria2 7zip git winget
scoop reset *

# 4. Enable Developer Mode (Opens UI)
Write-Host "Ensure Developer Mode is ON to allow symlinks without Admin." -ForegroundColor Yellow
start ms-settings:developers

# 5. Clone Repository
$env:dotdir = "$HOME/windots"
if (-not (Test-Path $env:dotdir)) {
    git clone --recurse-submodules -c core.symlinks=true https://github.com/guruor/windots "$env:dotdir"
}
Set-Location $env:dotdir

# 6. Clean up old paths
Remove-Item "dotfiles-open" -Force -Recurse -ErrorAction SilentlyContinue
git clone --recurse-submodules -c core.symlinks=true https://github.com/guruor/dotfiles-open

Write-Host "Step 1 Complete. PLEASE RESTART YOUR TERMINAL and run install.ps1" -ForegroundColor Green
