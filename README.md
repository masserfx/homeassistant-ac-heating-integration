# Home Assistant Integrations - Complete Package

![Home Assistant](https://img.shields.io/badge/Home%20Assistant-2024.1+-blue?logo=home-assistant)
![Python](https://img.shields.io/badge/Python-3.8+-green?logo=python)
![License](https://img.shields.io/badge/License-MIT-yellow)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey)
![Stars](https://img.shields.io/github/stars/masserfx/homeassistant-ac-heating-integration?style=social)

**3 integrace pro Home Assistant** s interaktivními instalátory pro Linux, macOS a Windows.

## 🌟 Hlavní vlastnosti

- **229 entit** pro kompletní monitoring a ovládání
- **Cross-platform instalátory** s automatickou konfigurací
- **Modbus TCP** integrace pro AC Heating
- **GoodWe solar** monitoring přes UDP
- **Spotové ceny elektřiny** z OTE pro ČR

---

Tento projekt obsahuje 3 integrace pro Home Assistant:

## 📦 Obsah

1. **AC Heating Heat Pump** - Tepelné čerpadlo AC Heating Convert AW14
2. **GoodWe Solar** - Fotovoltaická elektrárna s baterií
3. **Czech Energy Spot Prices** - Spotové ceny elektřiny z OTE

---

## 🔥 1. AC Heating Heat Pump

### Popis
Kompletní integrace tepelného čerpadla AC Heating Convert AW14 přes Modbus TCP.

### Funkce
- **140 senzorů**: teploty, výkony, diagnostika
- **48 binárních senzorů**: stavy, alarmy
- **12 termostatů**: topné okruhy
- **2 ohřívače vody**: TUV 1-2

### Připojení
- IP: `192.168.X.X` (IP adresa tvého čerpadla)
- Port: `502`
- Protocol: Modbus TCP

### Instalace
```bash
# Soubory jsou v:
custom_components/ac_heating/

# Již nainstalováno na HA v:
/config/custom_components/ac_heating/
```

### Konfigurace v HA
1. Nastavení → Zařízení a služby → Přidat integraci
2. Vyhledej: "AC Heating Heat Pump"
3. Zadej:
   - IP adresa: IP tvého čerpadla (např. `192.168.1.100`)
   - Port: `502`
   - Interval: `30` sekund (doporučeno)

### Dostupné entity
```
Venkovní teplota: sensor.ac_heating_outdoor_temp
Výkon systému: sensor.ac_heating_system_power
Topné okruhy: climate.ac_heating_heating_circuit_1 až 12
TUV: water_heater.ac_heating_tuv_1 až 2
+ 186 dalších entit
```

---

## ☀️ 2. GoodWe Solar (Fotovoltaika)

### Popis
Monitoring fotovoltaické elektrárny s baterií GoodWe GW10K-ET.

### Funkce
- PV výkon (aktuální + denní)
- Stav baterie (SOC, výkon)
- Grid import/export
- Spotřeba domu
- Teplotní monitoring

### Připojení
- Inverter IP: `192.168.X.X` (automaticky detekováno instalátorem)
- Model: GW10K-ET (a další GoodWe modely)
- Protokol: UDP port 8899

### Instalace
Bridge script běží na vašem počítači a odesílá data do HA přes REST API.

```bash
# Instalátor automaticky nastaví bridge
# Pro manuální spuštění:
python3 goodwe_bridge.py

# Pro automatický start:
# Linux: systemd service
# macOS: LaunchAgent
# Windows: Task Scheduler
# (vše automaticky nakonfigurováno instalátorem)
```

### Dostupné entity
```
sensor.goodwe_pv_power          # Aktuální výkon PV
sensor.goodwe_battery_soc       # Stav baterie (%)
sensor.goodwe_grid_power        # Export/import do sítě
sensor.goodwe_house_consumption # Spotřeba domu
sensor.goodwe_pv_energy_today   # Dnešní výroba
+ 9 dalších senzorů
```

### Aktuální hodnoty (příklad)
```
PV výkon: 744 W
Dnešní výroba: 1.8 kWh
Baterie: 11%
Spotřeba domu: 515 W
Grid: 17 W (export)
```

---

## 💰 3. Czech Energy Spot Prices

### Popis
Spotové ceny elektřiny a plynu z OTE (Operátor trhu s elektřinou).

### Funkce
- Aktuální spotová cena
- Předpověď na 24 hodin
- Minimální/maximální ceny dne
- Podpora EUR i CZK
- Ceny elektřiny i plynu

### Zdroj dat
- OTE (ote-cr.cz)
- ČNB směnné kurzy
- Aktualizace každou hodinu

### Instalace
```bash
# Soubory jsou v:
custom_components/cz_energy_spot_prices/

# Již nainstalováno na HA v:
/config/custom_components/cz_energy_spot_prices/
```

### Konfigurace v HA
1. **Restartuj Home Assistant**
2. Nastavení → Zařízení a služby → Přidat integraci
3. Vyhledej: "Czech Energy Spot Prices"
4. Vyber:
   - Komodita: Elektřina (nebo Plyn)
   - Jednotka: kWh (nebo MWh)
   - Měna: CZK (nebo EUR)

### Dostupné entity
```
sensor.cz_spot_electricity_current_hour  # Aktuální cena
sensor.cz_spot_electricity_next_hour     # Příští hodina
sensor.cz_spot_electricity_today_min     # Min. cena dnes
sensor.cz_spot_electricity_today_max     # Max. cena dnes
binary_sensor.cz_spot_electricity_cheap  # Je teď levná elektřina?
```

### Využití v automatizacích
```yaml
# Příklad: Nabíjej baterii, když je elektřina levná
automation:
  - alias: "Nabíjení baterie při levné elektřině"
    trigger:
      - platform: state
        entity_id: binary_sensor.cz_spot_electricity_cheap
        to: "on"
    action:
      - service: water_heater.set_operation_mode
        target:
          entity_id: water_heater.ac_heating_tuv_1
        data:
          operation_mode: "electric"
```

---

## 🚀 Rychlá instalace (všechny integrace)

### Použití instalátoru

```bash
# 1. Klonuj repository
git clone https://github.com/masserfx/homeassistant-ac-heating-integration.git
cd homeassistant-ac-heating-integration

# 2. Spusť instalátor pro tvou platformu
cd installers/linux    # nebo macos / windows
./install.sh           # nebo install.ps1 na Windows

# 3. Instalátor se zeptá na:
#    - Home Assistant adresu
#    - SSH přihlašovací údaje
#    - GoodWe konfiguraci (volitelně)
```

### Po instalaci

1. **Restartuj Home Assistant**
   Nastavení → Systém → Restartovat

2. **Přidej integrace**
   Nastavení → Zařízení a služby → Přidat integraci
   - AC Heating Heat Pump
   - Czech Energy Spot Prices

3. **Ověř GoodWe bridge** (pokud instalováno)
   Senzory se objeví automaticky po startu bridge

---

## 📊 Celkový přehled entit

| Integrace | Senzory | Binární | Climate | Water Heater | Celkem |
|-----------|---------|---------|---------|--------------|--------|
| AC Heating | 140 | 48 | 12 | 2 | **202** |
| GoodWe Solar | 14 | 0 | 0 | 0 | **14** |
| CZ Spot Prices | ~10 | ~3 | 0 | 0 | **13** |
| **CELKEM** | **164** | **51** | **12** | **2** | **229** |

---

## 🔧 Údržba

### Logy
```bash
# Zobraz logy Home Assistant:
ssh user@homeassistant.local
tail -f /config/home-assistant.log | grep -E "ac_heating|goodwe|cz_energy"
```

### Restart integrací
```bash
# Přes Developer Tools → YAML → Reload:
# - Template entities
# - Automations
# - Scripts
```

### Update integrací
```bash
# AC Heating a GoodWe: Manuální update souborů
# CZ Spot Prices: Podporuje HACS updates
```

---

## 🆘 Troubleshooting

### AC Heating: Nelze se připojit
```bash
# Test Modbus připojení:
python3 -c "from pymodbus.client import ModbusTcpClient; \
  c = ModbusTcpClient('YOUR_IP', 502); print(c.connect())"

# Zkontroluj dostupnost:
ping YOUR_HEAT_PUMP_IP
telnet YOUR_HEAT_PUMP_IP 502
```

### GoodWe: Bridge nepracuje
```bash
# Zkontroluj běžící bridge:
ps aux | grep goodwe_bridge
# Restart:
pkill -f goodwe_bridge && python3 goodwe_bridge.py &
```

### CZ Spot Prices: Žádná data
```bash
# Zkontroluj OTE API:
curl "https://www.ote-cr.cz/cs/kratkodobe-trhy/elektrina/denni-trh/@@chart-data?report_date=$(date +%Y-%m-%d)"
```

---

## 📝 Poznámky

### Požadavky

**Home Assistant:**
- Home Assistant Core 2024.1+
- SSH addon (Advanced SSH nebo Terminal & SSH)
- API Access token pro GoodWe bridge

**Síťové požadavky:**
- AC Heating: Modbus TCP port 502
- GoodWe: UDP port 8899
- Home Assistant: HTTP port 8123

### Bezpečnost

- ✅ Všechny integrace běží v lokální síti
- ✅ Žádné externí připojení (kromě OTE API)
- ⚠️ Modbus TCP bez autentizace - doporučen firewall
- ✅ SSH připojení s autentizací (heslo nebo klíč)

### Modbus Registry

Kompletní dokumentace registrů:
- Holding registers: 0-285
- Coil registers: 0-86
- Detaily v `xCC_modbus-2.0.pdf`

---

## 📚 Odkazy

- AC Heating: `custom_components/ac_heating/`
- GoodWe: `goodwe_bridge.py` + `README_GOODWE.md`
- CZ Spot Prices: https://github.com/rnovacek/homeassistant_cz_energy_spot_prices

---

**Vytvořeno:** 2025-11-07
**Verze:** 1.0.0
**Status:** ✅ Všechny integrace funkční
