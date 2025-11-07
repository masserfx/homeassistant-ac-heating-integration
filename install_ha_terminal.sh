#!/bin/bash

# AC Heating Heat Pump - Instalační skript pro HA terminál
# Spusť tento skript přímo v Home Assistant terminálu

set -e

echo "🚀 AC Heating Heat Pump - Instalace"
echo "===================================="
echo ""

# Vytvoř složku
echo "📁 Vytvářím složku..."
mkdir -p /config/custom_components/ac_heating
cd /config/custom_components/ac_heating

# Vytvoř manifest.json
echo "📄 Vytvářím manifest.json..."
cat > manifest.json << 'MANIFEST_EOF'
{
  "domain": "ac_heating",
  "name": "AC Heating Heat Pump",
  "codeowners": ["@ac_heating"],
  "config_flow": true,
  "documentation": "https://github.com/ac-heating/homeassistant",
  "iot_class": "local_polling",
  "issue_tracker": "https://github.com/ac-heating/homeassistant/issues",
  "requirements": ["pymodbus==3.11.3"],
  "version": "1.0.0"
}
MANIFEST_EOF

# Vytvoř const.py
echo "📄 Vytvářím const.py..."
cat > const.py << 'CONST_EOF'
"""Constants for the AC Heating integration."""

DOMAIN = "ac_heating"
CONST_EOF

# Vytvoř strings.json
echo "📄 Vytvářím strings.json..."
cat > strings.json << 'STRINGS_EOF'
{
  "config": {
    "step": {
      "user": {
        "title": "AC Heating Heat Pump",
        "description": "Nastavte připojení k tepelnému čerpadlu AC Heating",
        "data": {
          "host": "IP adresa",
          "port": "Port",
          "scan_interval": "Interval aktualizace (sekundy)"
        }
      }
    },
    "error": {
      "cannot_connect": "Nepodařilo se připojit k tepelnému čerpadlu",
      "unknown": "Neočekávaná chyba"
    },
    "abort": {
      "already_configured": "Toto zařízení je již nakonfigurováno"
    }
  }
}
STRINGS_EOF

echo ""
echo "✅ Základní soubory vytvořeny!"
echo ""
echo "📥 Nyní stáhnu Python soubory..."
echo ""

# Informace pro uživatele
cat << 'INFO'
⚠️  DŮLEŽITÉ: Python soubory jsou příliš dlouhé pro tento skript.

Prosím pokračuj jedním z následujících způsobů:

1️⃣  SSH s klíčem (DOPORUČENO):
   Spusť na svém počítači:

   cd /Users/lhradek/code/HomeAssistant/ac_heating_integration
   scp -i ~/.ssh/tvuj_klic -r custom_components/ac_heating/*.py root@homeassistant.local:/config/custom_components/ac_heating/

2️⃣  Studio Code Server:
   - Otevři http://homeassistant.local:8321
   - Otevři složku /config/custom_components/ac_heating/
   - Vytvoř Python soubory (__init__.py, sensor.py, atd.)
   - Zkopíruj obsah z lokálních souborů

3️⃣  File Editor addon:
   - Nainstaluj File Editor addon
   - Vytvoř soubory v /config/custom_components/ac_heating/
   - Zkopíruj obsah z lokálních souborů

INFO

echo ""
echo "📋 Seznam souborů k vytvoření:"
echo "   - __init__.py (hlavní modul)"
echo "   - config_flow.py (konfigurace)"
echo "   - sensor.py (senzory)"
echo "   - binary_sensor.py (stavy)"
echo "   - climate.py (topné okruhy)"
echo "   - water_heater.py (TUV)"
echo ""
echo "Aktuální stav:"
ls -lah /config/custom_components/ac_heating/
