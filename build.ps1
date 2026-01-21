# ZMK Firmware Build Script für Windows
# Macropad 3x3 mit Nice!Nano v2

param(
    [switch]$Setup,      # Erstinstallation durchführen
    [switch]$Update,     # West-Abhängigkeiten aktualisieren
    [switch]$Clean       # Build-Ordner löschen
)

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
$ZephyrVersion = "3.5.0"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ZMK Macropad 3x3 Firmware Builder" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Funktion: Prüft ob ein Befehl existiert
function Test-CommandExists {
    param($Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# Funktion: Abhängigkeiten prüfen
function Test-Dependencies {
    Write-Host "Prüfe Abhängigkeiten..." -ForegroundColor Yellow
    
    $missing = @()
    
    if (-not (Test-CommandExists "python")) {
        $missing += "Python 3.10+ (https://www.python.org/downloads/)"
    }
    
    if (-not (Test-CommandExists "git")) {
        $missing += "Git (https://git-scm.com/download/win)"
    }
    
    if (-not (Test-CommandExists "cmake")) {
        $missing += "CMake (https://cmake.org/download/)"
    }
    
    if (-not (Test-CommandExists "ninja")) {
        $missing += "Ninja (via: pip install ninja)"
    }
    
    if (-not (Test-CommandExists "west")) {
        $missing += "West (via: pip install west)"
    }
    
    if ($missing.Count -gt 0) {
        Write-Host ""
        Write-Host "FEHLER: Folgende Abhängigkeiten fehlen:" -ForegroundColor Red
        foreach ($dep in $missing) {
            Write-Host "  - $dep" -ForegroundColor Red
        }
        Write-Host ""
        Write-Host "Installationsanleitung:" -ForegroundColor Yellow
        Write-Host "1. Python installieren: winget install Python.Python.3.12" -ForegroundColor White
        Write-Host "2. Git installieren: winget install Git.Git" -ForegroundColor White
        Write-Host "3. CMake installieren: winget install Kitware.CMake" -ForegroundColor White
        Write-Host "4. Python-Pakete: pip install west ninja" -ForegroundColor White
        Write-Host "5. Zephyr SDK installieren (siehe unten)" -ForegroundColor White
        Write-Host ""
        return $false
    }
    
    Write-Host "Alle Basis-Abhängigkeiten gefunden!" -ForegroundColor Green
    return $true
}

# Funktion: Zephyr SDK prüfen
function Test-ZephyrSDK {
    $sdkPath = "$env:USERPROFILE\.zephyr-sdk"
    $sdkPathAlt = "$env:USERPROFILE\zephyr-sdk-$ZephyrVersion"
    
    if ((Test-Path $sdkPath) -or (Test-Path $sdkPathAlt) -or $env:ZEPHYR_SDK_INSTALL_DIR) {
        Write-Host "Zephyr SDK gefunden!" -ForegroundColor Green
        return $true
    }
    
    Write-Host ""
    Write-Host "WARNUNG: Zephyr SDK nicht gefunden!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Zephyr SDK Installation:" -ForegroundColor Cyan
    Write-Host "1. Download: https://github.com/zephyrproject-rtos/sdk-ng/releases" -ForegroundColor White
    Write-Host "2. Datei: zephyr-sdk-$ZephyrVersion`_windows-x86_64.7z" -ForegroundColor White
    Write-Host "3. Entpacken nach: $env:USERPROFILE\.zephyr-sdk" -ForegroundColor White
    Write-Host "4. SDK Setup ausführen: .\.zephyr-sdk\setup.cmd" -ForegroundColor White
    Write-Host ""
    return $false
}

# Funktion: West initialisieren
function Initialize-West {
    Write-Host "Initialisiere West Workspace..." -ForegroundColor Yellow
    
    Push-Location $ProjectRoot
    try {
        if (-not (Test-Path ".west")) {
            west init -l config
            if ($LASTEXITCODE -ne 0) { throw "West init fehlgeschlagen" }
        }
        
        Write-Host "Aktualisiere ZMK und Abhängigkeiten..." -ForegroundColor Yellow
        west update
        if ($LASTEXITCODE -ne 0) { throw "West update fehlgeschlagen" }
        
        Write-Host "Exportiere Zephyr..." -ForegroundColor Yellow
        west zephyr-export
        
        Write-Host "Installiere Python-Abhängigkeiten..." -ForegroundColor Yellow
        pip install -r zmk/zephyr/scripts/requirements.txt --quiet
        
        Write-Host "Setup abgeschlossen!" -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}

# Funktion: Firmware bauen
function Build-Firmware {
    Write-Host ""
    Write-Host "Baue Firmware für Nice!Nano v2 + Macropad3x3..." -ForegroundColor Cyan
    
    Push-Location $ProjectRoot
    try {
        $configPath = (Resolve-Path "config").Path -replace '\\', '/'
        
        $buildArgs = @(
            "build",
            "-s", "zmk/app",
            "-b", "nice_nano_v2",
            "--pristine"
        )
        
        if ($Clean) {
            $buildArgs += "-p"
        }
        
        $buildArgs += "--"
        $buildArgs += "-DSHIELD=macropad3x3"
        $buildArgs += "-DZMK_CONFIG=$configPath"
        
        Write-Host "Befehl: west $($buildArgs -join ' ')" -ForegroundColor DarkGray
        
        & west @buildArgs
        
        if ($LASTEXITCODE -ne 0) {
            throw "Build fehlgeschlagen!"
        }
        
        # Firmware kopieren
        $uf2File = "build\zephyr\zmk.uf2"
        if (Test-Path $uf2File) {
            $outputFile = "macropad3x3_nice_nano_v2.uf2"
            Copy-Item $uf2File $outputFile -Force
            
            Write-Host ""
            Write-Host "============================================" -ForegroundColor Green
            Write-Host "  BUILD ERFOLGREICH!" -ForegroundColor Green
            Write-Host "============================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "Firmware: $outputFile" -ForegroundColor Cyan
            Write-Host "Größe: $([math]::Round((Get-Item $outputFile).Length / 1024, 2)) KB" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Flashing:" -ForegroundColor Yellow
            Write-Host "1. Nice!Nano per USB verbinden" -ForegroundColor White
            Write-Host "2. Reset-Taster 2x schnell drücken" -ForegroundColor White
            Write-Host "3. UF2-Datei auf NICENANO-Laufwerk kopieren" -ForegroundColor White
        }
    }
    finally {
        Pop-Location
    }
}

# Hauptlogik
if (-not (Test-Dependencies)) {
    exit 1
}

if ($Setup) {
    Test-ZephyrSDK
    Initialize-West
    exit 0
}

if ($Update) {
    Push-Location $ProjectRoot
    west update
    Pop-Location
    exit 0
}

if ($Clean) {
    if (Test-Path "$ProjectRoot\build") {
        Remove-Item -Recurse -Force "$ProjectRoot\build"
        Write-Host "Build-Ordner gelöscht." -ForegroundColor Green
    }
}

# Prüfen ob West initialisiert ist
if (-not (Test-Path "$ProjectRoot\.west")) {
    Write-Host "West Workspace nicht initialisiert!" -ForegroundColor Red
    Write-Host "Führe zuerst aus: .\build.ps1 -Setup" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-ZephyrSDK)) {
    Write-Host "Bitte installiere das Zephyr SDK und versuche es erneut." -ForegroundColor Red
    exit 1
}

Build-Firmware
