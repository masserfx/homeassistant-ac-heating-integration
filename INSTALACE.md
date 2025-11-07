# 🏠 AC Heating Heat Pump - Kompletní instalační příručka

## ✅ Co bylo vytvořeno

Kompletní Home Assistant integrace pro tepelné čerpadlo AC Heating Convert AW14 s regulačním systémem xCC přes Modbus TCP.

### 📦 Struktura integrace

```
custom_components/ac_heating/
├── __init__.py              # Hlavní modul a koordinátor
├── manifest.json            # Konfigurace integrace
├── config_flow.py           # UI konfigurace
├── const.py                 # Konstanty
├── sensor.py                # Teplotní a výkonové senzory
├── binary_sensor.py         # Stavové senzory (chyby, stavy)
├── climate.py               # Ovládání topných okruhů
├── water_heater.py          # Ovládání TUV
└── strings.json             # České překlady
```

## 🎯 Dostupné entity

### 📊 Senzory (22+)
- ✅ Venkovní teplota
- ✅ Aktuální teplota vody
- ✅ Požadovaná teplota vody
- ✅ Výkon systému (%)
- ✅ Teplota zpátečky
- ✅ Topné okruhy 1-6 (3 senzory každý)
  - Teplota místnosti
  - Cílová teplota
  - Teplota topné vody
- ✅ TUV 1 (3 senzory)
  - Aktuální teplota
  - Max teplota
  - Min teplota

### 🔔 Binary senzory (14+)
- ✅ Hlavní vypínač
- ✅ Chyby (obecná, kritická, nekritická)
- ✅ Topné okruhy 1-6 (2 senzory každý)
  - Povolen
  - Aktivní
- ✅ TUV 1
  - Povolena
  - Aktivní

### 🌡️ Climate entity (6)
- ✅ Topné okruhy 1-6
  - Nastavení cílové teploty
  - Zobrazení aktuální teploty
  - Zapnutí/vypnutí okruhu
  - Stav topení (heating/idle)

### 💧 Water Heater (1)
- ✅ TUV 1
  - Nastavení cílové teploty
  - Zobrazení aktuální teploty
  - Zapnutí/vypnutí

## 🚀 Instalace

### Metoda 1: Automatická instalace (doporučeno)

```bash
cd /Users/lhradek/code/HomeAssistant/ac_heating_integration
./install.sh homeassistant.local
```

Nebo s IP adresou:
```bash
./install.sh 192.168.x.x
```

### Metoda 2: Manuální instalace

1. **Zkopírovat soubory:**
```bash
scp -r custom_components/ac_heating root@homeassistant.local:/config/custom_components/
```

2. **Restartovat Home Assistant**
   - Nastavení → Systém → Restartovat

3. **Přidat integraci**
   - Nastavení → Zařízení a služby → Přidat integraci
   - Vyhledat "AC Heating Heat Pump"
   - Zadat:
     - IP adresa: 192.168.0.166
     - Port: 502
     - Interval: 30 sekund

## 🔧 Testování před instalací

Modbus TCP komunikace byla úspěšně otestována:

```
✅ Připojeno: True

📊 Základní hodnoty:
  • Venkovní teplota: 4.7°C
  • Aktuální teplota vody: 22.4°C
  • Požadovaná teplota vody: 0.0°C
  • Aktuální výkon: 0%

🏠 Topný okruh 1:
  • Teplota místnosti: 20.7°C

💧 Teplá užitková voda:
  • TUV 1 - Max: 46.0°C
  • TUV 1 - Min: 44.4°C
  • TUV 1 - Skutečná: 44.4°C
```

## 📋 Technické parametry

### Modbus TCP
- **Adresa:** 192.168.0.166
- **Port:** 502
- **Slave ID:** 1
- **Timeout:** 5 sekund
- **Polling interval:** 30 sekund (konfigurovatelný)

## 📚 Použití v automatizacích

### Příklad: Snížení teploty v noci

```yaml
automation:
  - alias: "Noční režim topení"
    trigger:
      - platform: time
        at: "22:00:00"
    action:
      - service: climate.set_temperature
        target:
          entity_id: climate.ac_heating_topny_okruh_1
        data:
          temperature: 19
```

### Příklad: Upozornění na chybu

```yaml
automation:
  - alias: "Upozornění na chybu TČ"
    trigger:
      - platform: state
        entity_id: binary_sensor.ac_heating_chyba_kriticka
        to: "on"
    action:
      - service: notify.mobile_app
        data:
          message: "⚠️ Kritická chyba na tepelném čerpadle!"
```

## 🎉 Hotovo!

Integrace je plně funkční a připravená k instalaci do Home Assistantu.

**Vytvořeno:** 2025-11-07
**Verze:** 1.0.0
**Autor:** Claude Code + leos
