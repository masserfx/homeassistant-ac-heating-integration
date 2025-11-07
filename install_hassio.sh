#!/bin/bash

# AC Heating Heat Pump - Instalace pro Advanced SSH & Web Terminal
# Username: hassio
# Password: 5164

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 AC Heating Heat Pump - Instalace${NC}\n"

HA_HOST="homeassistant.local"
HA_USER="hassio"
HA_PASS="5164"

echo -e "${YELLOW}📍 Připojuji se jako: ${HA_USER}@${HA_HOST}${NC}"
echo -e "${YELLOW}🔑 Heslo: ${HA_PASS}${NC}\n"

# Poznámka: sshpass automaticky zadá heslo
# Instalace sshpass pokud není nainstalován
if ! command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}📦 Instaluji sshpass...${NC}"
    brew install hudochenkov/sshpass/sshpass 2>/dev/null || {
        echo -e "${RED}❌ Nepodařilo se nainstalovat sshpass${NC}"
        echo -e "${YELLOW}💡 Alternativa: Použij manuální instalaci níže${NC}"
        echo ""
        echo "Spusť tyto příkazy (heslo: 5164):"
        echo ""
        echo "ssh hassio@homeassistant.local \"mkdir -p /config/custom_components\""
        echo "scp -r custom_components/ac_heating hassio@homeassistant.local:/config/custom_components/"
        echo "ssh hassio@homeassistant.local \"ls -lh /config/custom_components/ac_heating/\""
        echo ""
        exit 1
    }
fi

# Vytvoř složku
echo -e "${YELLOW}📁 Vytvářím složku custom_components...${NC}"
sshpass -p "$HA_PASS" ssh -o StrictHostKeyChecking=no "${HA_USER}@${HA_HOST}" "mkdir -p /config/custom_components"

# Zkopíruj soubory
echo -e "${YELLOW}📦 Kopíruji integraci...${NC}"
sshpass -p "$HA_PASS" scp -o StrictHostKeyChecking=no -r custom_components/ac_heating "${HA_USER}@${HA_HOST}":/config/custom_components/

echo -e "${GREEN}✅ Soubory úspěšně zkopírovány${NC}\n"

# Ověř instalaci
echo -e "${YELLOW}🔍 Ověřuji instalaci...${NC}"
sshpass -p "$HA_PASS" ssh -o StrictHostKeyChecking=no "${HA_USER}@${HA_HOST}" "ls -lh /config/custom_components/ac_heating/"

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
echo -e "   3. Zadej připojení:"
echo -e "      IP: ${GREEN}192.168.0.166${NC}"
echo -e "      Port: ${GREEN}502${NC}"
echo -e "      Interval: ${GREEN}30${NC} sekund"
echo -e ""
echo -e "${GREEN}✨ Hotovo!${NC}"
