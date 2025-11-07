#!/bin/bash

# Instalační skript pro AC Heating Heat Pump integraci
# Použití: ./install.sh [IP_ADRESA_HOME_ASSISTANT]

set -e

# Barvy pro výstup
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 AC Heating Heat Pump - Instalace do Home Assistant${NC}\n"

# Zkontrolovat, zda je zadána IP adresa
HA_HOST="${1:-homeassistant.local}"

echo -e "${YELLOW}📍 Cílový Home Assistant: ${HA_HOST}${NC}"
echo -e "${YELLOW}📂 Instalační cesta: /config/custom_components/ac_heating${NC}\n"

# Zkontrolovat dostupnost Home Assistantu
echo -e "${YELLOW}🔍 Testuji dostupnost Home Assistantu...${NC}"
if ping -c 1 -W 2 "$HA_HOST" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Home Assistant je dostupný${NC}\n"
else
    echo -e "${RED}❌ Home Assistant není dostupný na $HA_HOST${NC}"
    echo -e "${YELLOW}💡 Zkuste zadat IP adresu: ./install.sh 192.168.x.x${NC}"
    exit 1
fi

# Zkopírovat soubory přes SSH
echo -e "${YELLOW}📦 Kopíruji soubory do Home Assistantu...${NC}"

# Vytvořit složku custom_components, pokud neexistuje
ssh "root@$HA_HOST" "mkdir -p /config/custom_components" 2>/dev/null || {
    echo -e "${RED}❌ Nepodařilo se připojit přes SSH${NC}"
    echo -e "${YELLOW}💡 Ujistěte se, že:${NC}"
    echo -e "${YELLOW}   1. Je nainstalován SSH addon v Home Assistantu${NC}"
    echo -e "${YELLOW}   2. Máte správné SSH oprávnění${NC}"
    exit 1
}

# Zkopírovat integraci
scp -r custom_components/ac_heating "root@$HA_HOST:/config/custom_components/" 2>/dev/null || {
    echo -e "${RED}❌ Nepodařilo se zkopírovat soubory${NC}"
    exit 1
}

echo -e "${GREEN}✅ Soubory úspěšně zkopírovány${NC}\n"

# Zobrazit další kroky
echo -e "${GREEN}🎉 Instalace dokončena!${NC}\n"
echo -e "${YELLOW}📋 Další kroky:${NC}"
echo -e "   1. Restartujte Home Assistant (Nastavení → Systém → Restartovat)"
echo -e "   2. Jděte do Nastavení → Zařízení a služby → Přidat integraci"
echo -e "   3. Vyhledejte 'AC Heating Heat Pump'"
echo -e "   4. Zadejte IP adresu tepelného čerpadla (např. 192.168.0.166)"
echo -e ""
echo -e "${GREEN}✨ Integrace je připravena k použití!${NC}"
