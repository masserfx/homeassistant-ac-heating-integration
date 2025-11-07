#
# Home Assistant Integrations Installer - Windows
# Instaluje AC Heating, GoodWe Solar a CZ Energy Spot Prices
#
# Použití: .\install.ps1
# Spusť jako: PowerShell -ExecutionPolicy Bypass -File install.ps1
#

# Nastavení
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Barvy
function Write-Step {
    param($Message)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] " -ForegroundColor Blue -NoNewline
    Write-Host $Message
}

function Write-Success {
    param($Message)
    Write-Host "✓ " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Error-Custom {
    param($Message)
    Write-Host "✗ " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Write-Warning-Custom {
    param($Message)
    Write-Host "⚠ " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

# Banner
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║                                                           ║" -ForegroundColor Blue
Write-Host "║   Home Assistant Integration Installer - Windows         ║" -ForegroundColor Blue
Write-Host "║                                                           ║" -ForegroundColor Blue
Write-Host "║   • AC Heating Heat Pump (202 entities)                  ║" -ForegroundColor Blue
Write-Host "║   • GoodWe Solar (14 sensors)                            ║" -ForegroundColor Blue
Write-Host "║   • Czech Energy Spot Prices (13 entities)               ║" -ForegroundColor Blue
Write-Host "║                                                           ║" -ForegroundColor Blue
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

# Získání adresáře skriptu
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = (Get-Item $ScriptDir).Parent.Parent.FullName

# Kontrola složky custom_components
if (-not (Test-Path "$ProjectRoot\custom_components")) {
    Write-Error-Custom "Nelze najít složku custom_components. Jste ve správném adresáři?"
    exit 1
}

Write-Step "Detekce systému..."
$OSVersion = [System.Environment]::OSVersion.Version
Write-Success "Windows verze: $($OSVersion.Major).$($OSVersion.Minor)"

# Kontrola OpenSSH
Write-Step "Kontroluji OpenSSH..."
$sshPath = Get-Command ssh -ErrorAction SilentlyContinue

if (-not $sshPath) {
    Write-Warning-Custom "OpenSSH není nainstalován"
    Write-Host ""
    Write-Host "Instalace OpenSSH:"
    Write-Host "  1. Windows 10/11: Nastavení → Aplikace → Volitelné funkce → Přidat funkci → OpenSSH Client"
    Write-Host "  2. Nebo použij PuTTY: https://www.putty.org/"
    Write-Host ""

    $installSSH = Read-Host "Zkusit nainstalovat OpenSSH automaticky? (Y/n)"
    if ($installSSH -eq "" -or $installSSH -eq "Y" -or $installSSH -eq "y") {
        Write-Step "Instaluji OpenSSH..."
        try {
            Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
            Write-Success "OpenSSH nainstalován"
        } catch {
            Write-Error-Custom "Nelze nainstalovat OpenSSH. Instaluj ručně."
            exit 1
        }
    } else {
        Write-Error-Custom "OpenSSH je potřeba pro pokračování"
        exit 1
    }
} else {
    Write-Success "OpenSSH nalezen: $($sshPath.Source)"
}

# Kontrola Python (pro GoodWe bridge)
Write-Step "Kontroluji Python..."
$pythonPath = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonPath) {
    $pythonPath = Get-Command python3 -ErrorAction SilentlyContinue
}

if (-not $pythonPath) {
    Write-Warning-Custom "Python není nainstalován (potřebný pro GoodWe bridge)"
    Write-Host "Stáhni z: https://www.python.org/downloads/"
} else {
    $pythonVersion = & python --version 2>&1
    Write-Success "Python nalezen: $pythonVersion"
}

# Konfigurace
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "Konfigurace připojení k Home Assistant" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

# Home Assistant host
$HAHost = Read-Host "📍 IP/hostname Home Assistantu [homeassistant.local]"
if ([string]::IsNullOrEmpty($HAHost)) { $HAHost = "homeassistant.local" }

# SSH metoda
Write-Host ""
Write-Host "Vyber metodu SSH připojení:"
Write-Host "  1) Heslo (Advanced SSH & Web Terminal addon)"
Write-Host "  2) SSH klíč (Terminal & SSH addon)"
$SSHMethod = Read-Host "Volba [1]"
if ([string]::IsNullOrEmpty($SSHMethod)) { $SSHMethod = "1" }

if ($SSHMethod -eq "1") {
    # SSH s heslem
    $SSHUser = Read-Host "👤 SSH uživatel [hassio]"
    if ([string]::IsNullOrEmpty($SSHUser)) { $SSHUser = "hassio" }

    $SSHPassSecure = Read-Host "🔑 SSH heslo" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SSHPassSecure)
    $SSHPass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

} else {
    # SSH s klíčem
    $SSHUser = Read-Host "👤 SSH uživatel [root]"
    if ([string]::IsNullOrEmpty($SSHUser)) { $SSHUser = "root" }

    $SSHKey = Read-Host "🔑 Cesta k SSH klíči [$env:USERPROFILE\.ssh\id_rsa]"
    if ([string]::IsNullOrEmpty($SSHKey)) { $SSHKey = "$env:USERPROFILE\.ssh\id_rsa" }

    if (-not (Test-Path $SSHKey)) {
        Write-Error-Custom "SSH klíč nenalezen: $SSHKey"
        exit 1
    }
}

# Test SSH
Write-Host ""
Write-Step "Testuji SSH připojení..."

if ($SSHMethod -eq "1") {
    # S heslem - použijeme Plink (součást PuTTY) nebo sshpass alternativu
    # Windows OpenSSH podporuje hesla interaktivně, ale ne z příkazové řádky
    # Budeme potřebovat PuTTY/Plink nebo použít klíč

    Write-Warning-Custom "SSH s heslem vyžaduje interaktivní vstup nebo PuTTY/Plink"
    Write-Host "Pro automatickou instalaci doporučuji použít SSH klíč."
    Write-Host ""
    Write-Host "Pro manuální instalaci:"
    Write-Host "  1. Připoj se: ssh $SSHUser@$HAHost"
    Write-Host "  2. Vytvoř: mkdir -p /config/custom_components"
    Write-Host "  3. Zkopíruj složky ac_heating a cz_energy_spot_prices do /config/custom_components/"
    Write-Host ""

    $continue = Read-Host "Pokračovat s manuální instalací pomocí návodu? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        Write-Warning-Custom "Instalace zrušena"
        exit 0
    }

    # Manuální postup
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "Manuální instalace - následuj tyto kroky:" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host ""

    Write-Host "Krok 1: Připoj se přes SSH" -ForegroundColor Cyan
    Write-Host "  ssh $SSHUser@$HAHost"
    Write-Host "  (zadej heslo: $SSHPass)"
    Write-Host ""

    Write-Host "Krok 2: Vytvoř složku" -ForegroundColor Cyan
    Write-Host "  mkdir -p /config/custom_components"
    Write-Host ""

    Write-Host "Krok 3: Použij WinSCP nebo FileZilla k přenosu souborů" -ForegroundColor Cyan
    Write-Host "  - Stáhni WinSCP: https://winscp.net/"
    Write-Host "  - Připoj se k: $HAHost"
    Write-Host "  - Zkopíruj: $ProjectRoot\custom_components\ac_heating"
    Write-Host "             do: /config/custom_components/"
    Write-Host "  - Zkopíruj: $ProjectRoot\custom_components\cz_energy_spot_prices"
    Write-Host "             do: /config/custom_components/"
    Write-Host ""

    Write-Host "Krok 4: Restartuj Home Assistant" -ForegroundColor Cyan
    Write-Host "  Nastavení → Systém → Restartovat"
    Write-Host ""

    Write-Success "Návod zobrazen"
    exit 0

} else {
    # S klíčem
    $testCmd = "ssh -i `"$SSHKey`" -o StrictHostKeyChecking=no $SSHUser@$HAHost echo SSH OK"
    try {
        $result = Invoke-Expression $testCmd 2>&1
        if ($result -like "*SSH OK*") {
            Write-Success "SSH připojení funguje"
        } else {
            Write-Error-Custom "SSH připojení selhalo"
            exit 1
        }
    } catch {
        Write-Error-Custom "SSH připojení selhalo: $_"
        exit 1
    }
}

# Instalace s SSH klíčem
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "Začínám instalaci..." -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""

# 1. Vytvoř složku
Write-Step "Vytvářím složku custom_components..."
$createDirCmd = "ssh -i `"$SSHKey`" -o StrictHostKeyChecking=no $SSHUser@$HAHost 'mkdir -p /config/custom_components'"
try {
    Invoke-Expression $createDirCmd
    Write-Success "Složka vytvořena"
} catch {
    Write-Error-Custom "Nelze vytvořit složku: $_"
    exit 1
}

# 2. AC Heating
Write-Step "Instaluji AC Heating Heat Pump..."
$scpCmd = "scp -i `"$SSHKey`" -o StrictHostKeyChecking=no -r `"$ProjectRoot\custom_components\ac_heating`" ${SSHUser}@${HAHost}:/config/custom_components/"
try {
    Invoke-Expression $scpCmd
    Write-Success "AC Heating nainstalován (202 entit)"
} catch {
    Write-Error-Custom "Nelze zkopírovat AC Heating: $_"
    exit 1
}

# 3. CZ Energy Spot Prices
Write-Step "Instaluji Czech Energy Spot Prices..."
$scpCmd = "scp -i `"$SSHKey`" -o StrictHostKeyChecking=no -r `"$ProjectRoot\custom_components\cz_energy_spot_prices`" ${SSHUser}@${HAHost}:/config/custom_components/"
try {
    Invoke-Expression $scpCmd
    Write-Success "CZ Energy Spot Prices nainstalován (13 entit)"
} catch {
    Write-Error-Custom "Nelze zkopírovat CZ Energy Spot Prices: $_"
    exit 1
}

# GoodWe Bridge
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "GoodWe Solar Bridge" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

$installGoodWe = Read-Host "Instalovat GoodWe bridge? (y/N)"
if ($installGoodWe -eq "y" -or $installGoodWe -eq "Y") {
    if ($pythonPath) {
        Write-Step "Instaluji Python závislosti..."
        pip install goodwe requests

        Write-Host ""
        Write-Host "GoodWe bridge vyžaduje manuální konfiguraci:"
        Write-Host "  1. Zkopíruj goodwe_bridge.py z $ProjectRoot"
        Write-Host "  2. Nastav proměnné GOODWE_IP, HA_URL, HA_TOKEN"
        Write-Host "  3. Spusť: python goodwe_bridge.py"
        Write-Host ""
        Write-Host "Pro automatický start při bootu použij Task Scheduler:"
        Write-Host "  - Akce: Start a program"
        Write-Host "  - Program: python.exe"
        Write-Host "  - Argumenty: cesta\k\goodwe_bridge.py"
    } else {
        Write-Warning-Custom "Python není dostupný - GoodWe bridge nelze nainstalovat"
    }
}

# Finish
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "✓ Instalace dokončena!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host "Další kroky:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. " -NoNewline
Write-Host "Restartuj Home Assistant" -ForegroundColor Cyan
Write-Host "   Nastavení → Systém → Restartovat"
Write-Host ""
Write-Host "2. " -NoNewline
Write-Host "Přidej integrace" -ForegroundColor Cyan
Write-Host "   Nastavení → Zařízení a služby → Přidat integraci"
Write-Host ""
Write-Host "   • AC Heating Heat Pump"
Write-Host "     IP: 192.168.0.166, Port: 502"
Write-Host ""
Write-Host "   • Czech Energy Spot Prices"
Write-Host "     Elektřina, kWh, CZK"
Write-Host ""
Write-Host "Hotovo! 🎉" -ForegroundColor Green
Write-Host ""
