# Windows Installation Script for APK Reverse Engineering Tool
# PowerShell script for native Windows environments

# Requires: PowerShell 5.1 or later
# Run as Administrator

Write-Host "========================================" -ForegroundColor Green
Write-Host "APK Reverse Engineering Tool - Windows" -ForegroundColor Green
Write-Host "Dependency Installation Script" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Error: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    pause
    exit 1
}

# Function to download and extract
function Download-Extract {
    param(
        [string]$Url,
        [string]$OutputPath,
        [string]$ExtractPath
    )
    
    Write-Host "Downloading: $Url" -ForegroundColor Cyan
    Invoke-WebRequest -Uri $Url -OutFile $OutputPath -UseBasicParsing
    
    Write-Host "Extracting to: $ExtractPath" -ForegroundColor Cyan
    Expand-Archive -Path $OutputPath -DestinationPath $ExtractPath -Force
    
    Remove-Item $OutputPath -Force
}

# Create installation directory
$installDir = "$env:USERPROFILE\apk-tools"
New-Item -ItemType Directory -Force -Path $installDir | Out-Null
New-Item -ItemType Directory -Force -Path "$installDir\bin" | Out-Null
New-Item -ItemType Directory -Force -Path "$installDir\sdk" | Out-Null
New-Item -ItemType Directory -Force -Path "$installDir\utils" | Out-Null

Write-Host "Installation directory: $installDir" -ForegroundColor Green
Write-Host ""

# Check for Python
Write-Host "Checking Python installation..." -ForegroundColor Cyan
$pythonInstalled = $false
try {
    $pythonVersion = python --version 2>&1
    Write-Host "Python found: $pythonVersion" -ForegroundColor Green
    $pythonInstalled = $true
} catch {
    Write-Host "Python not found. Attempting to install..." -ForegroundColor Yellow
    
    # Download and install Python
    Write-Host "Downloading Python installer..." -ForegroundColor Cyan
    $pythonUrl = "https://www.python.org/ftp/python/3.11.7/python-3.11.7-amd64.exe"
    $pythonInstaller = "$env:TEMP\python-installer.exe"
    
    try {
        Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonInstaller -UseBasicParsing
        
        Write-Host "Installing Python (this may take a few minutes)..." -ForegroundColor Cyan
        Start-Process -FilePath $pythonInstaller -ArgumentList "/quiet", "InstallAllUsers=1", "PrependPath=1", "Include_test=0" -Wait -NoNewWindow
        
        Remove-Item $pythonInstaller -Force
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        Write-Host "Python installed successfully" -ForegroundColor Green
        $pythonInstalled = $true
    } catch {
        Write-Host "Failed to install Python automatically. Please install Python 3.11+ from https://www.python.org/downloads/" -ForegroundColor Red
        pause
        exit 1
    }
}

# Install Python dependencies
Write-Host "`nInstalling Python dependencies..." -ForegroundColor Cyan
$pythonPackages = @(
    "requests",
    "beautifulsoup4",
    "lxml",
    "androguard",
    "apkutils",
    "pyaxmlparser",
    "frida-tools"
)

foreach ($package in $pythonPackages) {
    Write-Host "  Installing $package..." -ForegroundColor Yellow
    pip install $package --upgrade
}

# Download and install Android SDK
Write-Host "`nInstalling Android SDK..." -ForegroundColor Cyan
$sdkDir = "$installDir\sdk"
$sdkUrl = "https://dl.google.com/android/repository/commandlinetools-win-9123335_latest.zip"
$sdkZip = "$env:TEMP\sdk-tools.zip"

if (-not (Test-Path "$sdkDir\cmdline-tools\latest")) {
    Download-Extract -Url $sdkUrl -OutputPath $sdkZip -ExtractPath "$env:TEMP\sdk-temp"
    
    # Move to correct location
    New-Item -ItemType Directory -Force -Path "$sdkDir\cmdline-tools\latest" | Out-Null
    Move-Item -Path "$env:TEMP\sdk-temp\cmdline-tools\*" -Destination "$sdkDir\cmdline-tools\latest&quot; -Force
    Remove-Item -Path "$env:TEMP\sdk-temp" -Recurse -Force
}

# Set environment variables
Write-Host "`nSetting environment variables..." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $sdkDir, "User")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $sdkDir, "User")

$oldPath = [Environment]::GetEnvironmentVariable("Path", "User")
$newPath = "$oldPath;$sdkDir\cmdline-tools\latest\bin;$sdkDir\platform-tools;$installDir\bin"
[Environment]::SetEnvironmentVariable("Path", $newPath, "User")

Write-Host "Environment variables set. You may need to restart your terminal." -ForegroundColor Green

# Install Android SDK components
Write-Host "`nInstalling Android SDK components..." -ForegroundColor Cyan
$env:ANDROID_HOME = $sdkDir
& "$sdkDir\cmdline-tools\latest\bin\sdkmanager.bat" --sdk_root=$sdkDir "platform-tools" "build-tools;33.0.1" "platforms;android-33"

# Download apktool
Write-Host "`nInstalling apktool..." -ForegroundColor Cyan
$apktoolUrl = "https://github.com/iBotPeaches/Apktool/releases/download/v2.8.1/apktool_2.8.1.jar"
$apktoolJar = "$installDir\bin\apktool.jar"
Invoke-WebRequest -Uri $apktoolUrl -OutFile $apktoolJar -UseBasicParsing

# Create apktool wrapper script
$apktoolBat = @"
@echo off
java -jar "$apktoolJar" %*
"@
Set-Content -Path "$installDir\bin\apktool.bat" -Value $apktoolBat

# Download jadx
Write-Host "`nInstalling jadx..." -ForegroundColor Cyan
$jadxUrl = "https://github.com/skylot/jadx/releases/download/v1.4.7/jadx-1.4.7.zip"
$jadxZip = "$env:TEMP\jadx.zip"
$jadxDir = "$installDir\jadx"

Download-Extract -Url $jadxUrl -OutputPath $jadxZip -ExtractPath $jadxDir

# Create wrapper scripts
$jadxBat = @"
@echo off
"$jadxDir\jadx-1.4.7\bin\jadx.bat" %*
"@
Set-Content -Path "$installDir\bin\jadx.bat" -Value $jadxBat

$jadxGuiBat = @"
@echo off
"$jadxDir\jadx-1.4.7\bin\jadx-gui.bat" %*
"@
Set-Content -Path "$installDir\bin\jadx-gui.bat" -Value $jadxGuiBat

# Download Frida gadgets
Write-Host "`nDownloading Frida gadgets..." -ForegroundColor Cyan
$fridaDir = "$installDir\frida-gadgets"
New-Item -ItemType Directory -Force -Path $fridaDir | Out-Null

try {
    $fridaVersion = (Invoke-WebRequest -Uri "https://api.github.com/repos/frida/frida/releases/latest" -UseBasicParsing | ConvertFrom-Json).tag_name
    Write-Host "Frida version: $fridaVersion" -ForegroundColor Green
    
    $architectures = @("android-arm", "android-arm64", "android-x86", "android-x86_64")
    foreach ($arch in $architectures) {
        Write-Host "  Downloading $arch..." -ForegroundColor Yellow
        $fridaUrl = "https://github.com/frida/frida/releases/download/$fridaVersion/frida-gadget-$fridaVersion-$arch.so.xz"
        $fridaFile = "$fridaDir\$arch.so.xz"
        
        try {
            Invoke-WebRequest -Uri $fridaUrl -OutFile $fridaFile -UseBasicParsing
            
            # Extract .xz file (requires 7-Zip or similar)
            Write-Host "    Note: .xz files need to be extracted with 7-Zip or WinRAR" -ForegroundColor Yellow
        } catch {
            Write-Host "    Failed to download $arch" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "Failed to determine Frida version" -ForegroundColor Yellow
}

# Create utility scripts
Write-Host "`nCreating utility scripts..." -ForegroundColor Cyan

# Certificate analyzer
$certAnalyzer = @"
# Certificate Analysis Utility

param(
    [Parameter(Mandatory=`$true)]
    [string]`$ApkFile
)

if (-not (Test-Path `$ApkFile)) {
    Write-Host "Error: APK file not found: `$ApkFile" -ForegroundColor Red
    exit 1
}

Write-Host "Analyzing certificate for: `$ApkFile" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green

# Extract APK
`$tempDir = Join-Path `$env:TEMP "apk-cert-analyzer-`$([guid]::NewGuid())"
New-Item -ItemType Directory -Force -Path `$tempDir | Out-Null

# Use Expand-Archive to extract APK (APK is a ZIP file)
try {
    Expand-Archive -Path `$ApkFile -DestinationPath `$tempDir -Force
    
    `$certFile = Join-Path `$tempDir "META-INF\CERT.RSA"
    if (Test-Path `$certFile) {
        Write-Host "Certificate Information:" -ForegroundColor Yellow
        keytool -printcert -file `$certFile
    } else {
        Write-Host "No certificate found in APK" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Failed to analyze certificate: `$_" -ForegroundColor Red
} finally {
    Remove-Item -Path `$tempDir -Recurse -Force -ErrorAction SilentlyContinue
}
"@
Set-Content -Path "$installDir\utils\cert-analyzer.ps1" -Value $certAnalyzer

# Permission analyzer
$permAnalyzer = @"
# Permission Analysis Utility

param(
    [Parameter(Mandatory=`$true)]
    [string]`$ApkFile
)

if (-not (Test-Path `$ApkFile)) {
    Write-Host "Error: APK file not found: `$ApkFile" -ForegroundColor Red
    exit 1
}

Write-Host "Analyzing permissions for: `$ApkFile" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green

# Try to use aapt from Android SDK
`$aaptPath = Join-Path `$env:ANDROID_HOME "build-tools\33.0.1\aapt.exe"
if (Test-Path `$aaptPath) {
    Write-Host "Using aapt for permission analysis..." -ForegroundColor Yellow
    
    `& `$aaptPath dump permissions `$ApkFile | Select-String "uses-permission:" | ForEach-Object {
        `$perm = `$_.ToString().Split("=")[1].Trim("'", '"')
        `$perm
    } | Out-File -FilePath "$env:TEMP\permissions.txt"
    
    `$permissions = Get-Content "$env:TEMP\permissions.txt"
    
    Write-Host "Total permissions: `$(`$permissions.Count)" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Dangerous permissions:" -ForegroundColor Yellow
    `$dangerous = @("READ_CONTACTS", "WRITE_CONTACTS", "READ_CALENDAR", "WRITE_CALENDAR", 
                   "CAMERA", "READ_EXTERNAL_STORAGE", "WRITE_EXTERNAL_STORAGE", 
                   "ACCESS_FINE_LOCATION", "ACCESS_COARSE_LOCATION", "RECORD_AUDIO", 
                   "READ_PHONE_STATE", "CALL_PHONE", "READ_SMS", "SEND_SMS", 
                   "RECEIVE_SMS", "ACCESS_WIFI_STATE")
    
    `$permissions | Where-Object { `$dangerous -contains `$_ } | ForEach-Object { Write-Host "  `$_" -ForegroundColor Red }
    
    Write-Host "`nAll permissions:" -ForegroundColor Yellow
    `$permissions | ForEach-Object { Write-Host "  `$_" }
    
    Remove-Item "$env:TEMP\permissions.txt" -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "Error: aapt not found at `$aaptPath" -ForegroundColor Red
    Write-Host "Make sure Android SDK is properly installed." -ForegroundColor Yellow
}
"@
Set-Content -Path "$installDir\utils\perm-analyzer.ps1" -Value $permAnalyzer

# Device info script
$deviceInfo = @"
# Device Information Utility

Write-Host "Connected Android Devices:" -ForegroundColor Green
Write-Host "==========================" -ForegroundColor Green

`$adbPath = Join-Path `$env:ANDROID_HOME "platform-tools\adb.exe"
if (Test-Path `$adbPath) {
    `& `$adbPath devices | ForEach-Object {
        if (`$_.Trim() -ne "" -and `$_.Trim() -ne "List of devices attached") {
            `$parts = `$_.Split("`t")
            `$deviceId = `$parts[0].Trim()
            `$status = `$parts[1].Trim()
            
            Write-Host "Device ID: `$deviceId" -ForegroundColor Cyan
            Write-Host "Status: `$status" -ForegroundColor Cyan
            
            if (`$status -eq "device") {
                Write-Host "Model: `$(`& `$adbPath -s `$deviceId shell getprop ro.product.model)" -ForegroundColor Yellow
                Write-Host "Manufacturer: `$(`& `$adbPath -s `$deviceId shell getprop ro.product.manufacturer)" -ForegroundColor Yellow
                Write-Host "Android Version: `$(`& `$adbPath -s `$deviceId shell getprop ro.build.version.release)" -ForegroundColor Yellow
                Write-Host "API Level: `$(`& `$adbPath -s `$deviceId shell getprop ro.build.version.sdk)" -ForegroundColor Yellow
                Write-Host "Architecture: `$(`& `$adbPath -s `$deviceId shell getprop ro.product.cpu.abi)" -ForegroundColor Yellow
            }
            Write-Host "----------------------------------"
        }
    }
} else {
    Write-Host "Error: adb not found at `$adbPath" -ForegroundColor Red
    Write-Host "Make sure Android SDK platform-tools are installed." -ForegroundColor Yellow
}
"@
Set-Content -Path "$installDir\utils\device-info.ps1" -Value $deviceInfo

# Create PowerShell profile aliases
Write-Host "`nCreating PowerShell profile aliases..." -ForegroundColor Cyan
$profilePath = $PROFILE.CurrentUserCurrentHost
$profileDir = Split-Path $profilePath -Parent

if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
}

$aliases = @"
# APK Reverse Engineering Tool Aliases
function apk-analyze { & "$installDir\utils\cert-analyzer.ps1" @args }
function perm-analyze { & "$installDir\utils\perm-analyzer.ps1" @args }
function device-info { & "$installDir\utils\device-info.ps1" @args }
"@

if (-not (Test-Path $profilePath)) {
    Set-Content -Path $profilePath -Value $aliases
} else {
    Add-Content -Path $profilePath -Value "`n$aliases"
}

Write-Host "Aliases added to PowerShell profile: $profilePath" -ForegroundColor Green

# Installation summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Installation Directory: $installDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installed Tools:" -ForegroundColor Yellow
Write-Host "  - Python 3.11+" -ForegroundColor White
Write-Host "  - Android SDK (Platform Tools, Build Tools 33.0.1)" -ForegroundColor White
Write-Host "  - apktool v2.8.1" -ForegroundColor White
Write-Host "  - jadx v1.4.7" -ForegroundColor White
Write-Host "  - Frida tools and gadgets" -ForegroundColor White
Write-Host "  - Python packages (androguard, frida-tools, etc.)" -ForegroundColor White
Write-Host ""
Write-Host "Available Commands (after restarting PowerShell):" -ForegroundColor Yellow
Write-Host "  apk-analyze <apk_file>     - Analyze APK certificate" -ForegroundColor White
Write-Host "  perm-analyze <apk_file>    - Analyze APK permissions" -ForegroundColor White
Write-Host "  device-info                - Show connected device information" -ForegroundColor White
Write-Host ""
Write-Host "Important Notes:" -ForegroundColor Red
Write-Host "  1. Restart PowerShell or run '. `$PROFILE' to load aliases" -ForegroundColor White
Write-Host "  2. Android SDK may require manual configuration" -ForegroundColor White
Write-Host "  3. Some tools may need additional Windows SDK components" -ForegroundColor White
Write-Host "  4. For Frida gadgets, extract .xz files with 7-Zip or WinRAR" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")