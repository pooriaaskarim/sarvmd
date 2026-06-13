# Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
# Licensed under the Business Source License 1.1 (BUSL-1.1).
# See the LICENSE file in the project root for details.

# -----------------------------------------------------------------------------
# SarvMD - Windows Build Setup Automation Script
# -----------------------------------------------------------------------------
# This script automates the installation and configuration of the environment
# required to compile and build SarvMD on Windows.
# -----------------------------------------------------------------------------

$ErrorActionPreference = "Stop"

# Define colors for beautiful UI output
function Write-Header ($text) {
    Write-Host "`n=========================================================================" -ForegroundColor Cyan
    Write-Host "  $text" -ForegroundColor Cyan -Bold
    Write-Host "=========================================================================" -ForegroundColor Cyan
}

function Write-Info ($text) {
    Write-Host "  [INFO] $text" -ForegroundColor Gray
}

function Write-Success ($text) {
    Write-Host "  [SUCCESS] $text" -ForegroundColor Green -Bold
}

function Write-Warning ($text) {
    Write-Host "  [WARNING] $text" -ForegroundColor Yellow -Bold
}

function Write-ErrorText ($text) {
    Write-Host "  [ERROR] $text" -ForegroundColor Red -Bold
}

# 1. Elevate to Administrator if needed (Visual Studio Build Tools requires it)
$isAdmin = [bool]([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warning "This script requires Administrator privileges to install Visual Studio Build Tools."
    Write-Info "Relaunching in an elevated PowerShell session..."
    try {
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        Write-Success "Elevated session launched. You can close this window."
        exit
    } catch {
        Write-ErrorText "Failed to launch elevated session. Please run PowerShell as Administrator and execute this script."
        exit 1
    }
}

Write-Header "SarvMD - Environment Setup & Windows Build Toolchain"

# 2. Add Git to User & Process Environment Path
Write-Header "Step 1: Locating and Configuring Git"
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if ($gitCmd) {
    Write-Success "Git is already configured in the environment PATH."
    Write-Info "Version: $(git --version)"
} else {
    $defaultGitPath = "C:\Program Files\Git\cmd"
    if (Test-Path "$defaultGitPath\git.exe") {
        Write-Info "Git detected at '$defaultGitPath'. Registering environment variables..."
        
        # Current Process PATH
        $env:PATH += ";$defaultGitPath"
        
        # Persistent User PATH
        $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
        if ($userPath -notlike "*C:\Program Files\Git\cmd*") {
            [System.Environment]::SetEnvironmentVariable("Path", $userPath + ";$defaultGitPath", "User")
            Write-Success "Git successfully added to persistent User PATH environment variable."
        } else {
            Write-Success "Git is already in persistent User PATH."
        }
    } else {
        Write-Warning "Git was not found in the default installation path ('$defaultGitPath')."
        Write-Info "Please make sure Git is installed. We will proceed with other setup steps."
    }
}

# 3. Install/Configure Visual Studio C++ Desktop Workload
Write-Header "Step 2: Installing/Configuring Visual Studio C++ Desktop Workload"
$vsWherePath = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
$vsInstallerPath = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe"
$hasCPPWorkload = $false
$existingVSPath = $null

if (Test-Path $vsWherePath) {
    Write-Info "Checking existing Visual Studio workloads..."
    $vsInstallations = & $vsWherePath -products * -requires Microsoft.VisualStudio.Workload.NativeDesktop -property installationPath
    if ($vsInstallations) {
        Write-Success "Visual Studio C++ Desktop development workload is already installed."
        $hasCPPWorkload = $true
    } else {
        # Check if there is an existing Visual Studio installation we can modify
        $existingVSPath = & $vsWherePath -products * -property installationPath | Select-Object -First 1
        if ($existingVSPath) {
            Write-Info "Found Visual Studio installed at '$existingVSPath' but the C++ Desktop workload is missing."
        }
    }
}

if (-not $hasCPPWorkload) {
    if ($existingVSPath -and (Test-Path $vsInstallerPath)) {
        Write-Info "Modifying existing Visual Studio installation to add C++ workload..."
        Write-Info "This may take several minutes. Please wait..."
        $process = Start-Process -FilePath $vsInstallerPath -ArgumentList "modify --installPath `"$existingVSPath`" --add Microsoft.VisualStudio.Workload.NativeDesktop --passive --norestart --wait" -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            Write-Success "Visual Studio C++ Desktop workload added successfully to the existing installation!"
            $hasCPPWorkload = $true
            if ($process.ExitCode -eq 3010) {
                Write-Warning "A system reboot is recommended after the installation completes."
            }
        } else {
            Write-ErrorText "Failed to modify existing Visual Studio installation (Exit Code: $($process.ExitCode))."
            Write-Warning "Attempting fallback to standalone Build Tools installation..."
        }
    }

    if (-not $hasCPPWorkload) {
        Write-Info "Visual Studio C++ Desktop development workload not found."
        Write-Info "Downloading Visual Studio 2022 Build Tools bootstrapper..."
        
        $tempDir = Join-Path $env:TEMP "SarvMDSetup"
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }
        
        $bootstrapperPath = Join-Path $tempDir "vs_buildtools.exe"
        $bootstrapperUrl = "https://aka.ms/vs/17/release/vs_buildtools.exe"
        
        Write-Info "Downloading bootstrapper from $bootstrapperUrl..."
        Invoke-WebRequest -Uri $bootstrapperUrl -OutFile $bootstrapperPath
        
        Write-Info "Installing Visual Studio C++ Build Tools (Desktop development with C++ workload) silently..."
        Write-Info "This may take several minutes. Please wait..."
        
        # Running VS Build Tools silent installation
        $process = Start-Process -FilePath $bootstrapperPath -ArgumentList "--add Microsoft.VisualStudio.Workload.NativeDesktop --passive --norestart --wait" -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            Write-Success "Visual Studio C++ Build Tools installed successfully!"
            if ($process.ExitCode -eq 3010) {
                Write-Warning "A system reboot is recommended after the installation completes."
            }
        } else {
            Write-ErrorText "Visual Studio C++ Build Tools installation exited with code $($process.ExitCode)."
            Write-Warning "You may need to install the 'Desktop development with C++' workload manually via the Visual Studio Installer."
        }
    }
}

# 4. Install Flutter SDK
Write-Header "Step 3: Setting Up Flutter SDK"
$flutterPath = "A:\flutter"
$flutterBin = "$flutterPath\bin"

$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutterCmd) {
    Write-Success "Flutter is already configured in the environment PATH."
    Write-Info "Location: $($flutterCmd.Source)"
} else {
    if (Test-Path "$flutterBin\flutter.bat") {
        Write-Info "Flutter SDK detected at '$flutterPath' but not in the environment PATH. Configuring..."
    } else {
        Write-Info "Flutter SDK not found on this machine."
        
        $flutterZipUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.44.0-stable.zip"
        $flutterTempZip = Join-Path $env:TEMP "flutter_windows_3.44.0-stable.zip"
        
        Write-Info "Downloading Flutter SDK v3.44.0 (approx. 700MB)..."
        Write-Info "This may take a few minutes depending on your internet connection..."
        
        # Download Flutter SDK
        Invoke-WebRequest -Uri $flutterZipUrl -OutFile $flutterTempZip
        
        Write-Info "Extracting Flutter SDK to '$flutterPath'..."
        if (-not (Test-Path "A:\")) {
            Write-Warning "Drive A: is not accessible. Extracting to 'C:\src' instead."
            $flutterPath = "C:\src\flutter"
            $flutterBin = "$flutterPath\bin"
            $extractDest = "C:\src"
        } else {
            $extractDest = "A:\"
        }
        
        if (-not (Test-Path $extractDest)) {
            New-Item -ItemType Directory -Path $extractDest -Force | Out-Null
        }
        
        # Extract the archive
        Expand-Archive -Path $flutterTempZip -DestinationPath $extractDest -Force
        
        # Clean up zip
        Remove-Item -Path $flutterTempZip -Force
        Write-Success "Flutter SDK successfully downloaded and extracted."
    }
    
    # Add to persistent User PATH
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$flutterBin*") {
        [System.Environment]::SetEnvironmentVariable("Path", $userPath + ";$flutterBin", "User")
        Write-Success "Flutter SDK successfully added to persistent User PATH."
    }
    
    # Add to current Process PATH
    $env:PATH += ";$flutterBin"
}

# 5. Run Flutter Doctor to initialize and verify
Write-Header "Step 4: Verifying Flutter Installation"
Write-Info "Running 'flutter doctor'..."
& flutter doctor

# 6. Setup Windows platform templates in sarvmd_ui
Write-Header "Step 5: Enabling Windows Platform Support in sarvmd_ui"
$sarvmdUiPath = Join-Path $PSScriptRoot "apps\sarvmd_ui"

if (Test-Path $sarvmdUiPath) {
    Push-Location $sarvmdUiPath
    try {
        Write-Info "Initializing Windows platform templates..."
        & flutter create --platforms=windows .
        Write-Success "Windows platform templates generated successfully!"
        
        Write-Info "Fetching packages and resolving workspace dependencies..."
        & flutter pub get
        Write-Success "Dependencies resolved successfully!"
    } catch {
        Write-ErrorText "Failed to initialize Windows support inside `apps/sarvmd_ui`."
    } finally {
        Pop-Location
    }
} else {
    Write-ErrorText "Could not locate `apps/sarvmd_ui` at '$sarvmdUiPath'. Please make sure the path is correct."
}

Write-Header "Setup Complete!"
Write-Success "Windows build environment has been successfully configured!"
Write-Info "1. Please RESTART your IDE (Antigravity IDE) and any open terminal windows to apply the PATH changes."
Write-Info "2. Navigate to 'apps/sarvmd_ui' and run 'flutter run -d windows' to launch the app on Windows."
Write-Info "3. Run 'flutter build windows' to compile a release executable."
Write-Host "`nPress any key to exit..."
[void][System.Console]::ReadKey($true)
