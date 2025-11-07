#!/bin/bash
#
# Home Assistant Integrations Installer - macOS
# Instaluje AC Heating, GoodWe Solar a CZ Energy Spot Prices
#
# Použití: ./install.sh
#

set -e

# Barvy
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   Home Assistant Integration Installer - macOS           ║
║                                                           ║
║   • AC Heating Heat Pump (202 entities)                  ║
║   • GoodWe Solar (14 sensors)                            ║
║   • Czech Energy Spot Prices (13 entities)               ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Funkce pro výpis
print_step() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Získání adresáře skriptu
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

# Kontrola, že jsme ve správném adresáři
if [ ! -d "$PROJECT_ROOT/custom_components" ]; then
    print_error "Nelze najít složku custom_components. Jste ve správném adresáři?"
    exit 1
fi

print_step "Detekce systému..."
OS_VERSION=$(sw_vers -productVersion)
print_success "macOS verze: $OS_VERSION"

# Kontrola Homebrew
print_step "Kontroluji Homebrew..."
if ! command -v brew &> /dev/null; then
    print_warning "Homebrew není nainstalován"
    echo "Homebrew je potřeba pro instalaci sshpass."
    read -p "$(echo -e ${BLUE}Instalovat Homebrew? [Y/n]:${NC} )" INSTALL_BREW
    INSTALL_BREW=${INSTALL_BREW:-Y}

    if [[ "$INSTALL_BREW" =~ ^[Yy]$ ]]; then
        print_step "Instaluji Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        print_success "Homebrew nainstalován"
    else
        print_error "Homebrew je potřeba pro pokračování"
        exit 1
    fi
else
    print_success "Homebrew nalezen"
fi

# Získání údajů od uživatele
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Konfigurace připojení k Home Assistant${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Home Assistant host
read -p "$(echo -e ${BLUE}📍 IP/hostname Home Assistantu [homeassistant.local]:${NC} )" HA_HOST
HA_HOST=${HA_HOST:-homeassistant.local}

# SSH metoda
echo ""
echo "Vyber metodu SSH připojení:"
echo "  1) Heslo (Advanced SSH & Web Terminal addon)"
echo "  2) SSH klíč (Terminal & SSH addon)"
read -p "$(echo -e ${BLUE}Volba [1]:${NC} )" SSH_METHOD
SSH_METHOD=${SSH_METHOD:-1}

if [ "$SSH_METHOD" = "1" ]; then
    # SSH s heslem
    read -p "$(echo -e ${BLUE}👤 SSH uživatel [hassio]:${NC} )" SSH_USER
    SSH_USER=${SSH_USER:-hassio}

    read -sp "$(echo -e ${BLUE}🔑 SSH heslo:${NC} )" SSH_PASS
    echo ""

    # Kontrola sshpass
    if ! command -v sshpass &> /dev/null; then
        print_warning "sshpass není nainstalován"
        print_step "Instaluji sshpass přes Homebrew..."

        # Na macOS musíme použít hudochenkov/sshpass tap
        brew tap hudochenkov/sshpass || true
        brew install hudochenkov/sshpass/sshpass || {
            print_error "Nelze nainstalovat sshpass"
            echo "Zkus ručně: brew install hudochenkov/sshpass/sshpass"
            exit 1
        }

        print_success "sshpass nainstalován"
    fi

    SSH_CMD="sshpass -p '$SSH_PASS' ssh -o StrictHostKeyChecking=no $SSH_USER@$HA_HOST"
    SCP_CMD="sshpass -p '$SSH_PASS' scp -o StrictHostKeyChecking=no -r"

else
    # SSH s klíčem
    read -p "$(echo -e ${BLUE}👤 SSH uživatel [root]:${NC} )" SSH_USER
    SSH_USER=${SSH_USER:-root}

    read -p "$(echo -e ${BLUE}🔑 Cesta k SSH klíči [~/.ssh/id_rsa]:${NC} )" SSH_KEY
    SSH_KEY=${SSH_KEY:-~/.ssh/id_rsa}
    SSH_KEY="${SSH_KEY/#\~/$HOME}"  # Expand ~

    if [ ! -f "$SSH_KEY" ]; then
        print_error "SSH klíč nenalezen: $SSH_KEY"
        exit 1
    fi

    SSH_CMD="ssh -i '$SSH_KEY' -o StrictHostKeyChecking=no $SSH_USER@$HA_HOST"
    SCP_CMD="scp -i '$SSH_KEY' -o StrictHostKeyChecking=no -r"
fi

# Test SSH připojení
echo ""
print_step "Testuji SSH připojení..."
if eval "$SSH_CMD 'echo SSH OK'" &> /dev/null; then
    print_success "SSH připojení funguje"
else
    print_error "SSH připojení selhalo"
    echo "Zkontroluj:"
    echo "  - Je SSH addon spuštěný?"
    echo "  - Jsou správné přihlašovací údaje?"
    echo "  - Je Home Assistant dostupný? (ping $HA_HOST)"
    exit 1
fi

# GoodWe konfigurace
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Konfigurace GoodWe Solar Bridge${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

read -p "$(echo -e ${BLUE}Instalovat GoodWe bridge? [y/N]:${NC} )" INSTALL_GOODWE
INSTALL_GOODWE=${INSTALL_GOODWE:-N}

if [[ "$INSTALL_GOODWE" =~ ^[Yy]$ ]]; then
    read -p "$(echo -e ${BLUE}📍 IP adresa GoodWe inverteru:${NC} )" GOODWE_IP
    read -p "$(echo -e ${BLUE}🏠 Home Assistant URL [http://$HA_HOST:8123]:${NC} )" HA_URL
    HA_URL=${HA_URL:-http://$HA_HOST:8123}
    read -p "$(echo -e ${BLUE}🔑 HA API Token:${NC} )" HA_TOKEN
fi

# Shrnutí konfigurace
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Shrnutí konfigurace${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Home Assistant: $HA_HOST"
echo "SSH uživatel: $SSH_USER"
echo "SSH metoda: $([ $SSH_METHOD = 1 ] && echo 'Heslo' || echo 'Klíč')"
if [[ "$INSTALL_GOODWE" =~ ^[Yy]$ ]]; then
    echo "GoodWe inverter: $GOODWE_IP"
    echo "GoodWe bridge: ANO"
fi
echo ""

read -p "$(echo -e ${BLUE}Pokračovat s instalací? [Y/n]:${NC} )" CONFIRM
CONFIRM=${CONFIRM:-Y}

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    print_warning "Instalace zrušena"
    exit 0
fi

# Instalace
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Začínám instalaci...${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 1. AC Heating
print_step "Instaluji AC Heating Heat Pump..."
eval "$SSH_CMD 'mkdir -p /config/custom_components'" || {
    print_error "Nelze vytvořit složku custom_components"
    exit 1
}

cd "$PROJECT_ROOT"
eval "$SCP_CMD custom_components/ac_heating $SSH_USER@$HA_HOST:/config/custom_components/" || {
    print_error "Nelze zkopírovat AC Heating"
    exit 1
}
print_success "AC Heating nainstalován (202 entit)"

# 2. CZ Energy Spot Prices
print_step "Instaluji Czech Energy Spot Prices..."
eval "$SCP_CMD custom_components/cz_energy_spot_prices $SSH_USER@$HA_HOST:/config/custom_components/" || {
    print_error "Nelze zkopírovat CZ Energy Spot Prices"
    exit 1
}
print_success "CZ Energy Spot Prices nainstalován (13 entit)"

# 3. GoodWe Bridge
if [[ "$INSTALL_GOODWE" =~ ^[Yy]$ ]]; then
    print_step "Instaluji GoodWe Solar Bridge..."

    # Zkontroluj Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python3 není nainstalován"
        echo "Instaluj: brew install python3"
        exit 1
    fi

    # Vytvoř konfigurační soubor
    cat > /tmp/goodwe_bridge_config.py << EOF
GOODWE_IP = "$GOODWE_IP"
HA_URL = "$HA_URL"
HA_TOKEN = "$HA_TOKEN"
EOF

    # Vytvoř bridge skript
    cat > /tmp/goodwe_bridge.py << 'PYEOF'
#!/usr/bin/env python3
"""GoodWe to Home Assistant Bridge"""
import asyncio
import time
import logging
from datetime import datetime
import goodwe
import requests

# Import konfigurace
from goodwe_bridge_config import GOODWE_IP, HA_URL, HA_TOKEN

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def main():
    """Main bridge loop"""
    logger.info(f"Připojuji k GoodWe inverteru na {GOODWE_IP}...")

    try:
        inverter = await goodwe.connect(GOODWE_IP)
        logger.info(f"Připojen: {inverter.model_name}")
    except Exception as e:
        logger.error(f"Nelze připojit k inverteru: {e}")
        return

    headers = {
        "Authorization": f"Bearer {HA_TOKEN}",
        "Content-Type": "application/json"
    }

    while True:
        try:
            runtime_data = await inverter.read_runtime_data()

            for sensor in runtime_data:
                if sensor.value is not None:
                    entity_id = f"sensor.goodwe_{sensor.id_}"
                    payload = {
                        "state": sensor.value,
                        "attributes": {
                            "unit_of_measurement": sensor.unit,
                            "friendly_name": f"GoodWe {sensor.name}",
                            "device_class": "power" if "power" in sensor.id_ else None
                        }
                    }

                    url = f"{HA_URL}/api/states/{entity_id}"
                    try:
                        requests.post(url, json=payload, headers=headers, timeout=5)
                    except Exception as e:
                        logger.error(f"Chyba při odesílání {entity_id}: {e}")

            logger.info(f"Data odeslána v {datetime.now().strftime('%H:%M:%S')}")

        except Exception as e:
            logger.error(f"Chyba při čtení dat: {e}")

        await asyncio.sleep(30)

if __name__ == "__main__":
    asyncio.run(main())
PYEOF

    chmod +x /tmp/goodwe_bridge.py

    # Instaluj závislosti
    print_step "Instaluji Python závislosti..."
    pip3 install --user goodwe requests || {
        print_warning "Nelze nainstalovat závislosti, zkus ručně: pip3 install goodwe requests"
    }

    # Zkopíruj do Library
    mkdir -p ~/Library/HomeAssistantBridge
    cp /tmp/goodwe_bridge.py ~/Library/HomeAssistantBridge/
    cp /tmp/goodwe_bridge_config.py ~/Library/HomeAssistantBridge/

    # Vytvoř LaunchAgent pro automatický start
    cat > ~/Library/LaunchAgents/com.homeassistant.goodwebridge.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.homeassistant.goodwebridge</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/python3</string>
        <string>$HOME/Library/HomeAssistantBridge/goodwe_bridge.py</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$HOME/Library/HomeAssistantBridge</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/goodwe-bridge.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/goodwe-bridge-error.log</string>
</dict>
</plist>
EOF

    # Načti LaunchAgent
    launchctl load ~/Library/LaunchAgents/com.homeassistant.goodwebridge.plist 2>/dev/null || true
    launchctl start com.homeassistant.goodwebridge

    print_success "GoodWe Solar Bridge nainstalován jako LaunchAgent (14 senzorů)"
fi

# Finish
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Instalace dokončena!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Další kroky:${NC}"
echo ""
echo "1. ${BLUE}Restartuj Home Assistant${NC}"
echo "   Nastavení → Systém → Restartovat"
echo ""
echo "2. ${BLUE}Přidej integrace${NC}"
echo "   Nastavení → Zařízení a služby → Přidat integraci"
echo ""
echo "   • AC Heating Heat Pump"
echo "     IP: 192.168.0.166, Port: 502"
echo ""
echo "   • Czech Energy Spot Prices"
echo "     Elektřina, kWh, CZK"
echo ""
if [[ "$INSTALL_GOODWE" =~ ^[Yy]$ ]]; then
echo "3. ${BLUE}Zkontroluj GoodWe bridge${NC}"
echo "   launchctl list | grep goodwe"
echo "   tail -f ~/Library/Logs/goodwe-bridge.log"
echo ""
fi
echo -e "${GREEN}Hotovo! 🎉${NC}"
echo ""
