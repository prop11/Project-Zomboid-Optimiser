@echo off
setlocal
set "PZO_GOG_DIR=%~dp0"
title Project Zomboid Optimiser (PZO) - GOG Installer

where powershell >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Windows PowerShell was not found on your system.
    echo Please install or enable Windows PowerShell to run this installer.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "$f = Get-Content -LiteralPath '%~f0'; $start = 0; for ($i=0; $i -lt $f.Length; $i++) { if ($f[$i] -eq '# __START_POWERSHELL__') { $start = $i + 1; break } }; $ps = ($f[$start..($f.Length - 1)]) -join [Environment]::NewLine; [ScriptBlock]::Create($ps).Invoke()"
pause
exit /b %errorlevel%

# __START_POWERSHELL__
# ==============================================================================
# Project Zomboid Optimiser (PZO) - GOG Edition Installer & Engine Setup
# Installs Workshop Mod for GOG & Optionally Downloads High-Performance Engine
# ==============================================================================

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  Project Zomboid Optimiser (PZO) - GOG Edition Setup                " -ForegroundColor Cyan
Write-Host "  Comprehensive Mod & High-Performance Java Engine Installer          " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

$ScriptDir = if ($env:PZO_GOG_DIR) { $env:PZO_GOG_DIR.TrimEnd('\') } else { $PWD.Path }
$JarFileName    = "PZOptimEngine.jar"
$NativeDllName  = "pzo_native64.dll"
$TargetFileName = "ProjectZomboid64.json"
$BackupFolder   = "Installer_Backups"
$ZomboidDir     = Join-Path $HOME "Zomboid"
$ZomboidLuaDir  = Join-Path $ZomboidDir "Lua"
$ZomboidModsDir = Join-Path $ZomboidDir "mods"
$TargetModDir   = Join-Path $ZomboidModsDir "MPOptimiser"

# Guard against running game
$runningPZ = Get-Process -Name "ProjectZomboid64", "ProjectZomboid32" -ErrorAction SilentlyContinue
if ($runningPZ) {
    Write-Host "`n[!] Notice: Project Zomboid is currently running." -ForegroundColor Yellow
    Write-Host "    Please close Project Zomboid to prevent file permission locks." -ForegroundColor Yellow
    Write-Host "    Press Enter once the game is closed to continue..." -ForegroundColor Gray
    Read-Host
}

if (-not (Test-Path -LiteralPath $ZomboidLuaDir -ErrorAction SilentlyContinue)) {
    New-Item -ItemType Directory -Path $ZomboidLuaDir -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $ZomboidModsDir -ErrorAction SilentlyContinue)) {
    New-Item -ItemType Directory -Path $ZomboidModsDir -Force | Out-Null
}

# ==============================================================================
# STEP 1: INSTALL LUA WORKSHOP MOD
# ==============================================================================
Write-Host "`n[Step 1/2] Installing Project Zomboid Optimiser Mod..." -ForegroundColor Cyan

$candidateModDirs = @(
    (Join-Path $ScriptDir "Contents\mods\MPOptimiser"),
    (Join-Path $ScriptDir "MPOptimiser"),
    $ScriptDir
)
$sourceModDir = $null
foreach ($cmd in $candidateModDirs) {
    if (Test-Path -LiteralPath (Join-Path $cmd "mod.info") -ErrorAction SilentlyContinue) {
        $sourceModDir = $cmd
        break
    }
}

if ($sourceModDir) {
    Write-Host "  Source files located: $sourceModDir" -ForegroundColor Gray
    if (-not (Test-Path -LiteralPath $TargetModDir)) {
        New-Item -ItemType Directory -Path $TargetModDir -Force | Out-Null
    }

    # Copy mod directory contents recursively
    Copy-Item -Path (Join-Path $sourceModDir "*") -Destination $TargetModDir -Recurse -Force
    Write-Host "  [SUCCESS] Mod installed to: $TargetModDir" -ForegroundColor Green

    # Register mod in Zomboid\mods\default.txt
    $defaultTxt = Join-Path $ZomboidModsDir "default.txt"
    try {
        if (Test-Path -LiteralPath $defaultTxt) {
            $dtContent = Get-Content -LiteralPath $defaultTxt -Raw -ErrorAction SilentlyContinue
            if ($dtContent -and ($dtContent -notmatch "mod\s*=\s*MPOptimizer")) {
                if ($dtContent -match "(?s)(mods\s*\{)(.*?)(\})") {
                    $newContent = $dtContent -replace "(?s)(mods\s*\{)", "`$1`r`n    mod = MPOptimizer,"
                    [System.IO.File]::WriteAllText($defaultTxt, $newContent, [System.Text.Encoding]::UTF8)
                    Write-Host "  [+] Mod auto-enabled in default.txt" -ForegroundColor Green
                }
            } else {
                Write-Host "  [+] Mod is already registered in default.txt" -ForegroundColor Gray
            }
        } else {
            $initDefault = "VERSION = 1,`r`n`r`nmods`r`n{`r`n    mod = MPOptimizer,`r`n}`r`n`r`nmaps`r`n{`r`n}`r`n"
            [System.IO.File]::WriteAllText($defaultTxt, $initDefault, [System.Text.Encoding]::UTF8)
            Write-Host "  [+] Created default.txt with MPOptimizer enabled" -ForegroundColor Green
        }
    } catch {
        Write-Host "  [Notice] Could not update default.txt automatically: $($_.Exception.Message)" -ForegroundColor Gray
    }
} else {
    Write-Host "  [WARNING] Could not locate 'MPOptimiser' source files in installer folder." -ForegroundColor Yellow
    Write-Host "  Please ensure install_gog.bat is run from the mod package directory." -ForegroundColor Yellow
}

# ==============================================================================
# HELPER FUNCTIONS FOR GOG DETECTION & ENGINE INSTALLATION
# ==============================================================================
function Find-GOGPZPath {
    Write-Host "`nSearching for GOG Project Zomboid installation..." -ForegroundColor Cyan

    # 1. GOG Galaxy Registry
    $gogKeys = @(
        "HKLM:\SOFTWARE\GOG.com\Games\1441704940",
        "HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games\1441704940",
        "HKLM:\SOFTWARE\GOG.com\Games\1440163914",
        "HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games\1440163914"
    )
    foreach ($k in $gogKeys) {
        if (Test-Path $k) {
            $p = (Get-ItemProperty -Path $k -Name "path" -ErrorAction SilentlyContinue).path
            if ($p -and (Test-Path (Join-Path $p "ProjectZomboid64.exe"))) {
                return $p
            }
        }
    }

    # 2. Windows Uninstall Registry
    $uninstallRoots = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    )
    foreach ($uRoot in $uninstallRoots) {
        if (Test-Path $uRoot) {
            Get-ChildItem -Path $uRoot -ErrorAction SilentlyContinue | ForEach-Object {
                $dn = $_.GetValue("DisplayName")
                if ($dn -and $dn -like "*Project Zomboid*") {
                    $il = $_.GetValue("InstallLocation")
                    if ($il -and (Test-Path (Join-Path $il "ProjectZomboid64.exe"))) {
                        return $il
                    }
                }
            }
        }
    }

    # 3. Common Drive Paths
    $drives = [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.IsReady } | ForEach-Object { $_.Name }
    $commonSubfolders = @(
        "GOG Games\Project Zomboid",
        "Games\Project Zomboid",
        "Games\GOG Games\Project Zomboid",
        "Program Files (x86)\GOG Galaxy\Games\Project Zomboid",
        "Program Files\GOG Galaxy\Games\Project Zomboid",
        "GOG Galaxy\Games\Project Zomboid"
    )
    foreach ($drv in $drives) {
        foreach ($sub in $commonSubfolders) {
            $cand = Join-Path $drv $sub
            if (Test-Path (Join-Path $cand "ProjectZomboid64.exe")) {
                return $cand
            }
        }
    }

    return $null
}

function Download-PZOGitHubJar($targetFile) {
    $downloadUrl = "https://github.com/prop11/PZO-Launcher/releases/latest/download/PZOptimEngine.jar"
    Write-Host "`n[*] Downloading latest PZOptimEngine.jar from GitHub Releases..." -ForegroundColor Cyan
    Write-Host "    URL: $downloadUrl" -ForegroundColor Gray
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "PZO-GOG-Installer")
        $webClient.DownloadFile($downloadUrl, $targetFile)
        if (Test-Path -LiteralPath $targetFile -ErrorAction SilentlyContinue) {
            $sizeKB = [Math]::Round((Get-Item -LiteralPath $targetFile).Length / 1KB, 1)
            Write-Host "    [SUCCESS] Downloaded PZOptimEngine.jar ($sizeKB KB)" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "    [WARNING] Download error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    return $false
}

function Download-PZOGitHubDll($targetFile) {
    $downloadUrl = "https://github.com/prop11/PZO-Launcher/releases/latest/download/pzo_native64.dll"
    Write-Host "`n[*] Downloading latest pzo_native64.dll from GitHub Releases..." -ForegroundColor Cyan
    Write-Host "    URL: $downloadUrl" -ForegroundColor Gray
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "PZO-GOG-Installer")
        $webClient.DownloadFile($downloadUrl, $targetFile)
        if (Test-Path -LiteralPath $targetFile -ErrorAction SilentlyContinue) {
            $sizeKB = [Math]::Round((Get-Item -LiteralPath $targetFile).Length / 1KB, 1)
            Write-Host "    [SUCCESS] Downloaded pzo_native64.dll ($sizeKB KB)" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "    [WARNING] Download error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    return $false
}

function Write-JsonNoBOM($filePath, $content) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($filePath, $content, $utf8NoBom)
}

function Apply-PZOGOGConfiguration($InstallPath, $TargetFilePath, $BackupDir, $TargetFileName) {
    $TotalRamBytes = 0
    try {
        $osInfo = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $TotalRamBytes = [int64]$osInfo.TotalVisibleMemorySize * 1024
    } catch {
        try {
            $TotalRamBytes = [int64](Get-WmiObject Win32_OperatingSystem).TotalVisibleMemorySize * 1024
        } catch {}
    }
    $TotalRamGB = [Math]::Round($TotalRamBytes / 1GB)
    Write-Host "Detected System Physical RAM: $TotalRamGB GB" -ForegroundColor Cyan

    # Backup existing configuration
    if (-not (Test-Path -LiteralPath $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    }
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = Join-Path $BackupDir "$($TargetFileName)_$timestamp.bak"
    if (Test-Path -LiteralPath $TargetFilePath) {
        Copy-Item -LiteralPath $TargetFilePath -Destination $backupPath -Force
        Write-Host "Backup created: $backupPath" -ForegroundColor Gray
    }

    # Inspect existing JSON to detect steam flag
    $rawJson = ""
    if (Test-Path -LiteralPath $TargetFilePath) {
        $rawJson = Get-Content -LiteralPath $TargetFilePath -Raw -ErrorAction SilentlyContinue
    }
    $steamFlag = "-Dzomboid.steam=0"
    if ($rawJson -and $rawJson -match '"-Dzomboid\.steam=1"') {
        $steamFlag = "-Dzomboid.steam=1"
    }

    # Determine heap size based on detected RAM
    $xms = "-Xms4096m"
    $xmx = "-Xmx8192m"
    $ramProfile = 8
    if ($TotalRamGB -le 5) {
        $xms = "-Xms2048m"
        $xmx = "-Xmx4096m"
        $ramProfile = 4
    } elseif ($TotalRamGB -le 12) {
        $xms = "-Xms4096m"
        $xmx = "-Xmx8192m"
        $ramProfile = 8
    } elseif ($TotalRamGB -le 20) {
        $xms = "-Xms6144m"
        $xmx = "-Xmx12288m"
        $ramProfile = 12
    } else {
        $xms = "-Xms8192m"
        $xmx = "-Xmx16384m"
        $ramProfile = 16
    }

    Write-Host "Optimizing JVM Heap: Target = $ramProfile GB ($xms / $xmx)" -ForegroundColor Green

    # Generate optimized GOG ProjectZomboid64.json
    $jsonConfig = @"
{
    "mainClass": "com/pzoptimizer/PZOEntrypoint",
    "classpath": [
        ".",
        "PZOptimEngine.jar",
        "projectzomboid.jar"
    ],
    "vmArgs": [
        "--enable-native-access=ALL-UNNAMED",
        "--add-exports=java.base/jdk.internal.misc=ALL-UNNAMED",
        "$xms",
        "$xmx",
        "$steamFlag",
        "-Dzomboid.znetlog=1",
        "-Djava.library.path=win64/;.",
        "-XX:-CreateCoredumpOnCrash",
        "-XX:-OmitStackTraceInFastThrow",
        "-XX:+PerfDisableSharedMem",
        "-XX:+UseNUMA",
        "-XX:+AlwaysPreTouch"
    ],
    "windows": {
        "6.1": {
            "vmArgs": [
                "-XX:+UseG1GC"
            ]
        },
        "10.0.17134": {
            "vmArgs": [
                "-XX:+UseZGC"
            ]
        }
    }
}
"@

    Write-JsonNoBOM $TargetFilePath $jsonConfig
    Write-Host "Updated configuration: $TargetFilePath" -ForegroundColor Green

    # Write pzo_status.json
    try {
        $statusJson = '{"optimized":true,"ram_gb":' + $ramProfile + ',"g1gc":true,"pretouch":true,"version":"GOG-Installed"}'
        $statusFile = Join-Path $ZomboidLuaDir "pzo_status.json"
        Write-JsonNoBOM $statusFile $statusJson
        Write-Host "PZO status bridge written: $statusFile" -ForegroundColor Green
    } catch {}
}

# ==============================================================================
# STEP 2: OPTIONAL PZO HIGH-PERFORMANCE JAVA ENGINE
# ==============================================================================
Write-Host "`n[Step 2/2] PZO High-Performance Java Engine Installation" -ForegroundColor Cyan
Write-Host "----------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "The Java Engine runs alongside Project Zomboid to provide:" -ForegroundColor Gray
Write-Host "  * 8GB - 16GB Dedicated RAM Allocation (eliminates late-game stutter)" -ForegroundColor Gray
Write-Host "  * Whitelist Crash Shield (fixes missing texture / secondary drive crashes)" -ForegroundColor Gray
Write-Host "  * Multi-Story Building Occlusion Culling (smooth 60+ FPS indoors)" -ForegroundColor Gray
Write-Host "  * Generational GC & Off-Heap Memory Governor" -ForegroundColor Gray
Write-Host "----------------------------------------------------------------------" -ForegroundColor DarkGray

$choice = Read-Host "Would you like to install the Java Engine? [Y/N] (Default: Y)"
if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "Y" }

if ($choice -match "^[Yy]") {
    $InstallPath = Find-GOGPZPath

    if (-not $InstallPath) {
        Write-Host "`nCould not auto-locate GOG Project Zomboid installation." -ForegroundColor Yellow
        Write-Host "Please select the folder containing ProjectZomboid64.exe..." -ForegroundColor Yellow
        Add-Type -AssemblyName System.Windows.Forms
        $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $FolderBrowser.Description = "Select GOG Project Zomboid Directory (containing ProjectZomboid64.exe)"
        $FolderBrowser.ShowNewFolderButton = $false

        if ($FolderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $InstallPath = $FolderBrowser.SelectedPath
        } else {
            Write-Host "Java Engine installation skipped by user." -ForegroundColor Yellow
            Write-Host "`n[SUCCESS] Lua Mod installation complete!" -ForegroundColor Green
            return
        }
    }

    $exePath = Join-Path $InstallPath "ProjectZomboid64.exe"
    if (-not (Test-Path -LiteralPath $exePath)) {
        Write-Host "[ERROR] 'ProjectZomboid64.exe' was not found in: $InstallPath" -ForegroundColor Red
        Write-Host "Please run the installer again and select the correct game directory." -ForegroundColor Yellow
        return
    }

    Write-Host "Target GOG Project Zomboid Directory: $InstallPath" -ForegroundColor Green

    $InstalledJarPath = Join-Path $InstallPath $JarFileName
    $InstalledDllPath = Join-Path $InstallPath $NativeDllName
    $TargetFilePath   = Join-Path $InstallPath $TargetFileName
    $BackupDir        = Join-Path $InstallPath $BackupFolder

    # Check if already installed
    if (Test-Path -LiteralPath $InstalledJarPath) {
        Write-Host "`n[+] PZO Java Engine is already installed in this directory." -ForegroundColor Yellow
        Write-Host "  [1] Reinstall / Update to latest version" -ForegroundColor Cyan
        Write-Host "  [2] Uninstall PZO Engine (Restore original GOG settings)" -ForegroundColor Cyan
        Write-Host "  [3] Skip Engine Setup" -ForegroundColor Cyan
        $existingChoice = Read-Host "Select an option [1-3] (Default: 1)"
        if ([string]::IsNullOrWhiteSpace($existingChoice)) { $existingChoice = "1" }

        if ($existingChoice -eq "2") {
            Write-Host "`nUninstalling PZO Engine..." -ForegroundColor Cyan
            if (Test-Path -LiteralPath $InstalledJarPath) {
                Remove-Item -LiteralPath $InstalledJarPath -Force
                Write-Host "  Removed: $JarFileName" -ForegroundColor Green
            }
            if (Test-Path -LiteralPath $InstalledDllPath) {
                Remove-Item -LiteralPath $InstalledDllPath -Force
                Write-Host "  Removed: $NativeDllName" -ForegroundColor Green
            }
            $win64DllPath = Join-Path $InstallPath "win64\$NativeDllName"
            if (Test-Path -LiteralPath $win64DllPath) {
                Remove-Item -LiteralPath $win64DllPath -Force
                Write-Host "  Removed: win64\$NativeDllName" -ForegroundColor Green
            }
            # Clean up status files
            $statusFile = Join-Path $ZomboidLuaDir "pzo_status.json"
            if (Test-Path -LiteralPath $statusFile) {
                Remove-Item -LiteralPath $statusFile -Force -ErrorAction SilentlyContinue
            }
            # Restore latest backup
            if (Test-Path -LiteralPath $BackupDir) {
                $latestBak = Get-ChildItem -LiteralPath $BackupDir -Filter "$($TargetFileName)_*.bak" -ErrorAction SilentlyContinue |
                             Sort-Object LastWriteTime -Descending | Select-Object -First 1
                if ($latestBak) {
                    Copy-Item -LiteralPath $latestBak.FullName -Destination $TargetFilePath -Force
                    Write-Host "  Restored configuration from: $($latestBak.Name)" -ForegroundColor Green
                }
            }
            Write-Host "`n[SUCCESS] Uninstallation complete! GOG Project Zomboid restored to stock settings." -ForegroundColor Green
            return
        } elseif ($existingChoice -eq "3") {
            Write-Host "`nEngine setup skipped. Lua Mod remains installed." -ForegroundColor Cyan
            return
        }
    }

    # Locate or Download Jar
    $candidateJars = @(
        (Join-Path $ScriptDir $JarFileName),
        (Join-Path $ScriptDir "dist\$JarFileName"),
        (Join-Path $PWD.Path $JarFileName),
        (Join-Path $PWD.Path "dist\$JarFileName")
    )
    $SourceJar = $null
    foreach ($cj in $candidateJars) {
        if ($cj -and (Test-Path -LiteralPath $cj)) {
            $SourceJar = $cj
            break
        }
    }

    if ($SourceJar) {
        Write-Host "Using local engine file: $SourceJar" -ForegroundColor Gray
        Copy-Item -LiteralPath $SourceJar -Destination $InstalledJarPath -Force
        Write-Host "Installed: $JarFileName -> $InstallPath" -ForegroundColor Green
    } else {
        $tempJar = Join-Path $env:TEMP "PZOptimEngine.jar"
        if (Download-PZOGitHubJar $tempJar) {
            Copy-Item -LiteralPath $tempJar -Destination $InstalledJarPath -Force
            Remove-Item -LiteralPath $tempJar -Force -ErrorAction SilentlyContinue
            Write-Host "Installed: $JarFileName -> $InstallPath" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Could not download PZOptimEngine.jar. Continuing with Lua mod only." -ForegroundColor Red
            return
        }
    }

    # Locate or Download Native DLL (pzo_native64.dll)
    $candidateDlls = @(
        (Join-Path $ScriptDir $NativeDllName),
        (Join-Path $ScriptDir "dist\$NativeDllName"),
        (Join-Path $ScriptDir "native\$NativeDllName"),
        (Join-Path $PWD.Path $NativeDllName),
        (Join-Path $PWD.Path "dist\$NativeDllName")
    )
    $SourceDll = $null
    foreach ($cd in $candidateDlls) {
        if ($cd -and (Test-Path -LiteralPath $cd)) {
            $SourceDll = $cd
            break
        }
    }

    if ($SourceDll) {
        Write-Host "Using local native governor: $SourceDll" -ForegroundColor Gray
        Copy-Item -LiteralPath $SourceDll -Destination $InstalledDllPath -Force
        Write-Host "Installed Native Governor: $NativeDllName -> $InstallPath" -ForegroundColor Green
    } else {
        $tempDll = Join-Path $env:TEMP "pzo_native64.dll"
        if (Download-PZOGitHubDll $tempDll) {
            Copy-Item -LiteralPath $tempDll -Destination $InstalledDllPath -Force
            Remove-Item -LiteralPath $tempDll -Force -ErrorAction SilentlyContinue
            Write-Host "Installed Native Governor: $NativeDllName -> $InstallPath" -ForegroundColor Green
        } else {
            Write-Host "[WARNING] Could not download pzo_native64.dll. Continuing with Java Engine only." -ForegroundColor Yellow
        }
    }

    $win64Dir = Join-Path $InstallPath "win64"
    if ((Test-Path -LiteralPath $win64Dir) -and (Test-Path -LiteralPath $InstalledDllPath)) {
        $InstalledWin64Dll = Join-Path $win64Dir $NativeDllName
        Copy-Item -LiteralPath $InstalledDllPath -Destination $InstalledWin64Dll -Force
        Write-Host "Mirrored Native Governor -> $InstalledWin64Dll" -ForegroundColor Green
    }

    Apply-PZOGOGConfiguration $InstallPath $TargetFilePath $BackupDir $TargetFileName

    Write-Host "`n======================================================================" -ForegroundColor Cyan
    Write-Host "  [SUCCESS] PZO Installation Complete!                                " -ForegroundColor Green
    Write-Host "  - Mod installed to: $TargetModDir                                   " -ForegroundColor Green
    Write-Host "  - Java Engine installed to: $InstallPath                            " -ForegroundColor Green
    Write-Host "  You can now launch Project Zomboid via GOG Galaxy or executable!    " -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan
} else {
    Write-Host "`n[SUCCESS] Lua mod installation complete! Enjoy Project Zomboid Optimiser." -ForegroundColor Green
}
