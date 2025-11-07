#!/bin/bash
# AC Heating Heat Pump - Vytvoření integrace v Home Assistant
# SPUSŤ TENTO SKRIPT PŘÍMO V HOME ASSISTANT TERMINÁLU!
# (Nastavení → Doplňky → Advanced SSH & Web Terminal → OPEN WEB UI)

set -e

echo "🚀 AC Heating Heat Pump - Vytváření integrace"
echo "=============================================="
echo ""

# Vytvoř složku
mkdir -p /config/custom_components/ac_heating
cd /config/custom_components/ac_heating

echo "📁 Vytvořena složka: $(pwd)"
echo ""

# manifest.json
echo "📄 Vytvářím manifest.json..."
cat > manifest.json << 'EOF'
{
  "domain": "ac_heating",
  "name": "AC Heating Heat Pump",
  "codeowners": ["@ac_heating"],
  "config_flow": true,
  "documentation": "https://github.com/ac-heating/homeassistant",
  "iot_class": "local_polling",
  "requirements": ["pymodbus==3.11.3"],
  "version": "1.0.0"
}
EOF

# const.py
echo "📄 Vytvářím const.py..."
cat > const.py << 'EOF'
"""Constants for the AC Heating integration."""
DOMAIN = "ac_heating"
EOF

# strings.json
echo "📄 Vytvářím strings.json..."
cat > strings.json << 'EOF'
{
  "config": {
    "step": {
      "user": {
        "title": "AC Heating Heat Pump",
        "description": "Nastavte připojení k tepelnému čerpadlu",
        "data": {
          "host": "IP adresa",
          "port": "Port",
          "scan_interval": "Interval (sekundy)"
        }
      }
    },
    "error": {
      "cannot_connect": "Nelze se připojit",
      "unknown": "Neočekávaná chyba"
    }
  }
}
EOF

echo ""
echo "✅ Základní soubory vytvořeny!"
echo ""
echo "📋 Soubory ve složce:"
ls -lh

echo ""
echo "⏭️  Pokračuj spuštěním dalšího skriptu: ./create_integration_python.sh"
echo "   (nebo zkopíruj Python soubory ručně přes VS Code)"
