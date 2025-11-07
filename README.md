# Home Assistant Integrace - Kompletní balíček

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
- IP: `192.168.0.166`
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
   - IP adresa: `192.168.0.166`
   - Port: `502`
   - Interval: `30` sekund

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
- Inverter IP: `192.168.0.198`
- Model: GW10K-ET
- SN: 9010KETU218W0609

### Instalace
Bridge script běží na vašem počítači a odesílá data do HA přes REST API.

```bash
# Start bridge:
cd /Users/lhradek/code/HomeAssistant/ac_heating_integration/
python3 goodwe_bridge.py

# Pro automatický start (systemd):
sudo cp goodwe-bridge.service /etc/systemd/system/
sudo systemctl enable goodwe-bridge
sudo systemctl start goodwe-bridge
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

### Krok 1: Připojení na Home Assistant
```bash
ssh hassio@homeassistant.local
# Heslo: 5164
```

### Krok 2: Instalace souborů (už hotovo ✅)
```bash
# Všechny 3 integrace jsou již nainstalované v:
ls /config/custom_components/
# ac_heating/
# cz_energy_spot_prices/
```

### Krok 3: Restart Home Assistant
Nastavení → Systém → Restartovat

### Krok 4: Přidání integrací
Pro každou integraci:
1. Nastavení → Zařízení a služby → Přidat integraci
2. Vyhledej název integrace
3. Konfiguruj dle pokynů výše

### Krok 5: Start GoodWe bridge (na tvém počítači)
```bash
cd /Users/lhradek/code/HomeAssistant/ac_heating_integration/
python3 goodwe_bridge.py &
```

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
ssh hassio@homeassistant.local
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
# Test Modbus:
python3 -c "from pymodbus.client import ModbusTcpClient; c = ModbusTcpClient('192.168.0.166', 502); print(c.connect())"
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

### Home Assistant Access
- URL: `http://homeassistant.local:8123`
- SSH: `hassio@homeassistant.local` (heslo: 5164)
- API Token: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### Modbus Registry
- Kompletní dokumentace: `xCC_modbus-2.0.pdf`
- Holding registers: 0-285
- Coil registers: 0-86

### Bezpečnost
- Všechny služby běží v lokální síti
- Žádné externí připojení (kromě OTE API pro ceny)
- Modbus bez autentizace (firewall doporučen)

---

## 📚 Odkazy

- AC Heating: `custom_components/ac_heating/`
- GoodWe: `goodwe_bridge.py` + `README_GOODWE.md`
- CZ Spot Prices: https://github.com/rnovacek/homeassistant_cz_energy_spot_prices

---

**Vytvořeno:** 2025-11-07
**Verze:** 1.0.0
**Status:** ✅ Všechny integrace funkční
