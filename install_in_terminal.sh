#!/bin/bash
# Spusť tento skript PŘÍMO v Home Assistant terminálu (Web UI)

set -e

echo "🚀 AC Heating Heat Pump - Instalace"
echo "===================================="
echo ""

# Přepnout do config složky
cd /config

# Vytvořit custom_components složku
echo "📁 Vytvářím custom_components/ac_heating..."
mkdir -p custom_components/ac_heating
cd custom_components/ac_heating

# Stáhnout soubory z GitHub Gist nebo vytvořit ručně
echo ""
echo "📥 Nyní potřebuješ zkopírovat soubory..."
echo ""
echo "Použij jednu z metod:"
echo ""
echo "1️⃣  Přes Studio Code Server:"
echo "   - Otevři http://homeassistant.local:8321"
echo "   - Přejdi do /config/custom_components/ac_heating/"
echo "   - Vytvoř Python soubory"
echo ""
echo "2️⃣  Přes wget (pokud máš soubory online)"
echo ""
echo "3️⃣  Přes File Editor addon"
echo ""

# Zobrazit aktuální stav
echo "Složka vytvořena:"
pwd
ls -la

echo ""
echo "✅ Složka připravena!"
echo "📋 Nyní zkopíruj soubory z tvého počítače."
