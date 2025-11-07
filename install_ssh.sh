#!/bin/bash

# AC Heating Heat Pump - Instalace přes SSH s klíčem
# Použití: ./install_ssh.sh

set -e

# Barvy pro výstup
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 AC Heating Heat Pump - Instalace přes SSH${NC}\n"

# Konfigurace
HA_HOST="homeassistant.local"
SSH_KEY=""  # Ponechej prázdné pro automatickou detekci

# Automatická detekce SSH klíče
if [ -z "$SSH_KEY" ]; then
    echo -e "${YELLOW}🔍 Hledám SSH klíč...${NC}"

    # Zkus běžné klíče
    for key in ~/.ssh/id_rsa ~/.ssh/id_ed25519 ~/.ssh/id_ecdsa; do
        if [ -f "$key" ]; then
            echo -e "${GREEN}✅ Nalezen klíč: $key${NC}"
            SSH_KEY="$key"
            break
        fi
    done

    if [ -z "$SSH_KEY" ]; then
        echo -e "${RED}❌ Nenalezen žádný SSH klíč${NC}"
        echo -e "${YELLOW}💡 Zadej cestu k SSH klíči jako první parametr:${NC}"
        echo -e "${YELLOW}   ./install_ssh.sh ~/.ssh/tvuj_klic${NC}"
        exit 1
    fi
fi

# Možnost zadat klíč jako parametr
if [ -n "$1" ]; then
    SSH_KEY="$1"
    echo -e "${YELLOW}🔑 Používám klíč: $SSH_KEY${NC}"
fi

echo -e "${YELLOW}📍 Cíl: root@${HA_HOST}${NC}"
echo -e "${YELLOW}🔑 Klíč: ${SSH_KEY}${NC}\n"

# Test SSH připojení
echo -e "${YELLOW}🔍 Testuji SSH připojení...${NC}"
if ssh -i "$SSH_KEY" -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@"$HA_HOST" "echo 'SSH OK'" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ SSH připojení funguje${NC}\n"
else
    echo -e "${RED}❌ SSH připojení selhalo${NC}"
    echo -e "${YELLOW}💡 Zkontroluj:${NC}"
    echo -e "${YELLOW}   1. Je SSH addon spuštěný?${NC}"
    echo -e "${YELLOW}   2. Je správný SSH klíč nakonfigurován v addonu?${NC}"
    echo -e "${YELLOW}   3. Je Home Assistant dostupný?${NC}"
    exit 1
fi

# Vytvoř složku
echo -e "${YELLOW}📁 Vytvářím složku custom_components...${NC}"
ssh -i "$SSH_KEY" root@"$HA_HOST" "mkdir -p /config/custom_components" || {
    echo -e "${RED}❌ Nepodařilo se vytvořit složku${NC}"
    exit 1
}

# Zkopíruj soubory
echo -e "${YELLOW}📦 Kopíruji integraci...${NC}"
scp -i "$SSH_KEY" -r custom_components/ac_heating root@"$HA_HOST":/config/custom_components/ || {
    echo -e "${RED}❌ Nepodařilo se zkopírovat soubory${NC}"
    exit 1
}

echo -e "${GREEN}✅ Soubory úspěšně zkopírovány${NC}\n"

# Ověř instalaci
echo -e "${YELLOW}🔍 Ověřuji instalaci...${NC}"
ssh -i "$SSH_KEY" root@"$HA_HOST" "ls -lh /config/custom_components/ac_heating/"

echo ""
echo -e "${GREEN}🎉 Instalace dokončena!${NC}\n"
echo -e "${YELLOW}📋 Další kroky:${NC}"
echo -e "   1. Restartuj Home Assistant"
echo -e "      Nastavení → Systém → Restartovat"
echo -e ""
echo -e "   2. Přidej integraci"
echo -e "      Nastavení → Zařízení a služby → Přidat integraci"
echo -e "      Vyhledej: 'AC Heating Heat Pump'"
echo -e ""
echo -e "   3. Zadej připojení k tepelnému čerpadlu:"
echo -e "      IP adresa: ${GREEN}192.168.0.166${NC}"
echo -e "      Port: ${GREEN}502${NC}"
echo -e "      Interval: ${GREEN}30${NC} sekund"
echo -e ""
echo -e "${GREEN}✨ Hotovo!${NC}"
