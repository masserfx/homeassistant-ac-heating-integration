#!/bin/bash

# AC Heating Heat Pump - Instalace přes SSH s heslem
# Použití: ./install_password.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 AC Heating Heat Pump - Instalace přes SSH${NC}\n"

HA_HOST="homeassistant.local"

echo -e "${YELLOW}📍 Cíl: root@${HA_HOST}${NC}"
echo -e "${YELLOW}🔑 Použij heslo, které jsi nastavil v SSH addonu${NC}\n"

# Vytvoř složku
echo -e "${YELLOW}📁 Vytvářím složku custom_components...${NC}"
ssh root@"$HA_HOST" "mkdir -p /config/custom_components"

# Zkopíruj soubory
echo -e "${YELLOW}📦 Kopíruji integraci...${NC}"
scp -r custom_components/ac_heating root@"$HA_HOST":/config/custom_components/

echo -e "${GREEN}✅ Soubory úspěšně zkopírovány${NC}\n"

# Ověř instalaci
echo -e "${YELLOW}🔍 Ověřuji instalaci...${NC}"
ssh root@"$HA_HOST" "ls -lh /config/custom_components/ac_heating/"

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
