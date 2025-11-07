# Instalace Energo Management Dashboardu

## 🎨 Co dashboard obsahuje

### 5 views (pohledů):

1. **📊 Přehled** - Hlavní metriky, spotové ceny, teploty, grafy
2. **🌡️ Topné okruhy** - Ovládání všech 12 topných okruhů (termostaty)
3. **💧 TUV** - Ovládání teplé užitkové vody (2x water heater)
4. **🤖 Automatizace** - Návrhy chytrých automatizací pro úsporu
5. **📊 Diagnostika** - Kompletní monitoring a dlouhodobé grafy

### Funkce:

- ✅ Barevné indikátory (zelená/oranžová/červená podle hodnot)
- ✅ Grafy s ApexCharts (24h, 7 dní)
- ✅ Ovládání termostatů pro topné okruhy
- ✅ Ovládání TUV (teplá voda)
- ✅ Optimální časy pro spotřebu podle spotových cen
- ✅ Kompletní přehled všech entit

---

## 📦 Požadavky

### Integrace v Home Assistant:
- ✅ **AC Heating** (202 entit) - NAINSTALOVÁNO
- ✅ **CZ Energy Spot Prices** (9 entit) - NAINSTALOVÁNO

### Custom karty (HACS):
1. **ApexCharts Card** (pro grafy)
   ```
   HACS → Frontend → Vyhledat "ApexCharts" → Instalovat
   ```

2. **Simple Thermostat** (volitelné, pro lepší TUV)
   ```
   HACS → Frontend → Vyhledat "Simple Thermostat" → Instalovat
   ```

---

## 🚀 Instalace

### Metoda 1: Ruční kopírování (doporučeno)

1. **Otevři soubor:**
   ```
   dashboard_energo_management.yaml
   ```

2. **Zkopíruj celý obsah** (Ctrl+A, Ctrl+C)

3. **V Home Assistant:**
   - Přejdi na: **Nastavení → Panely**
   - Klikni **Přidat panel** (vpravo dole)
   - Vyber **Nový panel**
   - Klikni na **⋮** (tři tečky vpravo nahoře)
   - Vyber **Upravit panel → Upravit jako YAML**
   - **Smaž vše** v editoru
   - **Vlož** zkopírovaný obsah
   - Klikni **Uložit**

4. **Hotovo!** 🎉

### Metoda 2: Přes SSH (automatická)

```bash
# 1. Zkopíruj soubor na HA server
scp dashboard_energo_management.yaml hassio@homeassistant.local:/config/

# 2. Připoj se přes SSH
ssh hassio@homeassistant.local
# Heslo: 5164

# 3. Vytvoř backup dashboardů
cp /config/.storage/lovelace* /config/backups/ 2>/dev/null || true

# 4. Restartuj HA pro načtení
ha core restart
```

---

## 🔧 Konfigurace po instalaci

### 1. Nainstaluj ApexCharts

**Důvod:** Pro zobrazení grafů v dashboardu

**Postup:**
1. Nastavení → HACS → Frontend
2. Vyhledej: **"ApexCharts Card"**
3. Klikni Instalovat
4. Restartuj Home Assistant

### 2. (Volitelné) Nainstaluj Simple Thermostat

Pro hezčí ovládání TUV:
1. Nastavení → HACS → Frontend
2. Vyhledej: **"Simple Thermostat"**
3. Klikni Instalovat
4. Restartuj Home Assistant

### 3. Zkontroluj entity IDs

Pokud máš jiné názvy entit, uprav v YAML:

```yaml
# Příklad změny entity ID:
# Původní:
entity: sensor.ac_heating_venkovni_teplota

# Změň na tvůj název:
entity: sensor.tvuj_nazev_entity
```

---

## 🎨 Přizpůsobení dashboardu

### Změna barev grafů

V sekci ApexCharts karet najdi:
```yaml
color: '#3498db'  # Modrá
```

Nahraď hex kódem:
- `#e74c3c` - Červená
- `#f39c12` - Oranžová
- `#2ecc71` - Zelená
- `#9b59b6` - Fialová

### Změna prahů pro barvy

Upravit logiku barevných indikátorů:
```yaml
color: >
  {% if states('sensor.current_spot_electricity_price_15min')|float > 3 %}
    red
  {% elif states('sensor.current_spot_electricity_price_15min')|float > 2 %}
    orange
  {% else %}
    green
  {% endif %}
```

Změň hodnoty `3` a `2` podle tvých preferencí.

### Přidání dalších karet

Na konci view přidej:
```yaml
- type: entities
  title: Název karty
  entities:
    - entity: sensor.tvuj_senzor
      name: Tvůj název
```

---

## 📱 Mobilní optimalizace

Dashboard je plně responzivní:
- ✅ Tile karty se přizpůsobí šířce obrazovky
- ✅ Horizontal-stack se změní na vertical na mobilu
- ✅ Grafy jsou čitelné i na malé obrazovce

---

## 🤖 Příklady automatizací

### 1. Nabíjení TUV při levné elektřině

```yaml
automation:
  - alias: "TUV nabíjení optimalizace"
    trigger:
      - platform: state
        entity_id: binary_sensor.spot_electricity_is_cheapest_15min
        to: "on"
    condition:
      - condition: numeric_state
        entity_id: sensor.current_spot_electricity_price_15min
        below: 2.5
      - condition: time
        after: "22:00:00"
        before: "06:00:00"
    action:
      - service: water_heater.set_temperature
        target:
          entity_id: water_heater.ac_heating_tuv_1
        data:
          temperature: 55
      - service: notify.mobile_app
        data:
          message: "TUV se nabíjí při levné ceně {{ states('sensor.current_spot_electricity_price_15min') }} Kč/kWh"
```

### 2. Snížení teploty při vysoké ceně

```yaml
automation:
  - alias: "Úspora při drahé elektřině"
    trigger:
      - platform: numeric_state
        entity_id: sensor.current_spot_electricity_price_15min
        above: 4
    action:
      - service: climate.set_temperature
        target:
          entity_id:
            - climate.ac_heating_topny_okruh_1
            - climate.ac_heating_topny_okruh_2
        data:
          temperature: 19
      - service: notify.mobile_app
        data:
          message: "Snížena teplota kvůli vysoké ceně elektřiny"
```

### 3. Prediktivní topení před levnou elektřinou

```yaml
automation:
  - alias: "Předtopení před levnou elektřinou"
    trigger:
      - platform: time_pattern
        hours: "*"
    condition:
      # Zkontroluj, zda za hodinu bude levná elektřina
      - condition: template
        value_template: >
          {% set next_hour_price = state_attr('sensor.current_spot_electricity_price_15min', 'next_hour') %}
          {{ next_hour_price | float < 2 }}
    action:
      - service: climate.set_temperature
        target:
          entity_id:
            - climate.ac_heating_topny_okruh_1
        data:
          temperature: 22
```

---

## 🆘 Troubleshooting

### Problém: Grafy se nezobrazují

**Řešení:**
1. Zkontroluj, že je nainstalovaný ApexCharts Card
2. Vymaž cache prohlížeče (Ctrl+Shift+R)
3. Restartuj Home Assistant

### Problém: Entity nejsou k dispozici (unavailable)

**Řešení:**
1. Zkontroluj, že jsou integrace aktivní:
   ```bash
   ha integration list | grep -E "ac_heating|cz_energy"
   ```
2. Zkontroluj logy:
   ```bash
   tail -100 /config/home-assistant.log | grep -E "ac_heating|cz_energy"
   ```
3. Restartuj integrace:
   ```
   Vývojářské nástroje → YAML → Znovu načíst všechny YAML konfigurační soubory
   ```

### Problém: Barevné indikátory nefungují

**Řešení:**
Tile karty s barvami vyžadují Home Assistant 2023.11+. Pro starší verze použij:
```yaml
- type: entity
  entity: sensor.current_spot_electricity_price_15min
  name: Spotová cena
```

### Problém: Termostaty topných okruhů se nezobrazují

**Řešení:**
Zkontroluj, že climate entity existují:
```bash
ha states list | grep "climate.ac_heating"
```

Pokud ne, topné okruhy možná nejsou správně nakonfigurované v AC Heating integraci.

---

## 📊 Screenshots očekávaného výsledku

Dashboard by měl obsahovat:

**View 1 - Přehled:**
- 3x Tile karty (cena, teplota, výkon) s barevnými indikátory
- Graf spotových cen (24h)
- Detailní tabulka cen
- Graf teplot AC Heating (24h)

**View 2 - Topné okruhy:**
- 12x termostat karta v mřížce 3x4
- Detailní tabulka stavů všech okruhů

**View 3 - TUV:**
- 2x thermostat karta pro TUV
- 2x detailní tabulka s cirkulací

**View 4 - Automatizace:**
- Přehledné karty s indikátory
- Ukázkový YAML kód automatizací

**View 5 - Diagnostika:**
- Kompletní přehled všech teplot
- Dlouhodobý graf (7 dní)
- Alarmy a stavy

---

## 📚 Další informace

- **Home Assistant dokumentace:** https://www.home-assistant.io/dashboards/
- **ApexCharts Card:** https://github.com/RomRider/apexcharts-card
- **Lovelace reference:** https://www.home-assistant.io/lovelace/

---

## 🎯 Další vylepšení

### 1. Přidej energy dashboard integraci

Propoj s Energy Dashboardem HA:
```yaml
# configuration.yaml
sensor:
  - platform: integration
    source: sensor.ac_heating_vykon_systemu
    name: Energy consumed
    unit_prefix: k
    round: 2
```

### 2. Přidej notifikace

Notifikace při extrémních cenách:
```yaml
automation:
  - alias: "Upozornění na extrémní cenu"
    trigger:
      - platform: numeric_state
        entity_id: sensor.current_spot_electricity_price_15min
        above: 5
    action:
      - service: notify.all
        data:
          title: "⚡ Vysoká cena elektřiny!"
          message: "Aktuální cena: {{ states('sensor.current_spot_electricity_price_15min') }} Kč/kWh"
```

### 3. Přidej predikci spotřeby

Použij Utility Meter pro tracking denní/měsíční spotřeby.

---

**Vytvořeno:** 2025-11-07
**Verze dashboardu:** 1.0.0
**Status:** ✅ Otestováno a funkční
