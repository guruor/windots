# Define the function to download and extract fonts
function Download-Fonts
{
  param (
    [string[]]$FontUrls,
    [string]$DownloadDir
  )

  # Create the download directory if it doesn't exist
  if (!(Test-Path -Path $DownloadDir -PathType Container))
  {
    New-Item -Path $DownloadDir -ItemType Directory | Out-Null
  }

  # Function to check if fonts are already downloaded
  function Fonts-AlreadyDownloaded
  {
    param (
      [string[]]$FontUrls,
      [string]$DownloadDir
    )

    foreach ($url in $FontUrls)
    {
      $fileName = [System.IO.Path]::GetFileName($url)
      $fontFilePath = Join-Path -Path $DownloadDir -ChildPath $fileName

      if (!(Test-Path -Path $fontFilePath -PathType Leaf))
      {
        return $false
      }
    }

    return $true
  }

  # Check if fonts are already downloaded
  if (Fonts-AlreadyDownloaded -FontUrls $FontUrls -DownloadDir $DownloadDir)
  {
    Write-Output "Fonts are already downloaded in '$DownloadDir'. Skipping download."
  } else
  {
    # Download and extract fonts for each URL
    foreach ($url in $FontUrls)
    {
      DownloadAndExtract-Font -Url $url -DownloadDir $DownloadDir
    }
  }
}

# Function to download and extract fonts
function DownloadAndExtract-Font
{
  param (
    [string]$Url,
    [string]$DownloadDir
  )

  $fileName = Split-Path -Leaf $Url
  $filePath = Join-Path -Path $DownloadDir -ChildPath $fileName

  # Download the font ZIP file
  Invoke-WebRequest -Uri $Url -OutFile $filePath

  # Extract the contents of the ZIP file using 7z
  & "7z" x "$filePath" -o"$DownloadDir" -y
}

# Define the function to install fonts
function Install-Fonts
{
  param (
    [string[]]$FontUrls,
    [string]$DownloadDir
  )

  # Directory where fonts will be installed
  $fontsDir = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Fonts)

  # Install fonts from the download directory
  Install-FontsFromDir -DownloadDir $DownloadDir
}

# Function to check if a specific font is installed
function Test-FontInstalled
{
  param (
    [string]$FilePath
  )

  Add-Type -AssemblyName System.Drawing
  $fontCollection = New-Object System.Drawing.Text.InstalledFontCollection
  $fontFamilies = $fontCollection.Families

  $fontName = Get-FontNameFromFile -FilePath $FilePath
  foreach ($fontFamily in $fontFamilies)
  {
    if ($fontFamily.Name -eq $fontName)
    {
      return $true
    }
  }

  return $false
}

function Get-FontNameFromFile
{
  param (
    [string]$FilePath
  )
  Add-Type -AssemblyName System.Drawing
  $PrivateFontCollection = [System.Drawing.Text.PrivateFontCollection]::new()
  $PrivateFontCollection.AddFontFile($FilePath)
  return $PrivateFontCollection.Families[-1].Name
}

# Function to install fonts from a directory
function Install-FontsFromDir
{
  param (
    [string]$DownloadDir
  )

  # Get all ttf and otf font files from the download directory
  $fontFiles = Get-ChildItem -Path $DownloadDir -File -Force | Where-Object { $_.Extension -eq '.ttf' -or $_.Extension -eq '.otf' }

  if ($fontFiles.Count -eq 0)
  {
    Write-Output "No font files found in '$DownloadDir'. Installation aborted."
    return
  }

  # Create Shell.Application object
  $shellApp = New-Object -ComObject Shell.Application

  if (-not $shellApp)
  {
    Write-Output "Failed to create Shell.Application object. Installation aborted."
    return
  }

  # Font folder namespace (0x14) for installing fonts
  $fonts = $shellApp.NameSpace(0x14)

  if (-not $fonts)
  {
    Write-Output "Failed to get Fonts folder namespace. Installation aborted."
    return
  }

  # Install each font file
  foreach ($fontFile in $fontFiles)
  {
    $fontName = $fontFile.BaseName  # Get the base name of the font file (without extension)

    # Check if the font is already installed
    if (Test-FontInstalled -FilePath $fontFile.FullName)
    {
      Write-Output "Font '$fontName' is already installed. Skipping."
      continue  # Skip to the next font file
    }

    $fonts.CopyHere($fontFile.FullName)

    # Register the font in the registry (if possible)
    try
    {
      Add-Type -AssemblyName System.Drawing
      $FontCollection = [System.Drawing.Text.PrivateFontCollection]::new()
      $FontCollection.AddFontFile($fontFile.FullName)

      $RegistryValue = @{
        Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
        Name = $FontCollection.Families[-1].Name
        Value = $fontFile.FullName
      }

      New-ItemProperty @RegistryValue -ErrorAction Stop
    } catch
    {
      Write-Warning "Failed to register font '$fontName' in the registry. Error: $_"
    }
  }
}
