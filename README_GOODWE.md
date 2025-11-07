# GoodWe Inverter Integration s Home Assistant

## Zjištěné informace

### Střídač
- **Model**: GoodWe GW10K-ET
- **Sériové číslo**: 9010KETU218W0609
- **IP adresa**: 192.168.0.198
- **Firmware**: 04029-09-S11
- **Komunikace**: UDP port 8899

### Aktuální stav (11:20 7.11.2025)
- **PV výkon**: 786 W
- **Dnešní výroba**: 1.8 kWh
- **Celková výroba**: 26,986 kWh
- **Spotřeba domu**: 515 W
- **Grid výkon**: 14 W
- **Baterie SOC**: 11 %
- **Baterie výkon**: 0 W

## Problém s integrací

Home Assistant server (192.168.0.169) **nemůže komunikovat** se střídačem (192.168.0.198) kvůli síťové konfiguraci nebo firewallu. Lokální komunikace z jiných zařízení v síti funguje bez problémů.

## Řešení: GoodWe Bridge

Vytvořil jsem Python bridge (`goodwe_bridge.py`), který:
1. Běží na zařízení, které může komunikovat se střídačem
2. Pravidelně čte data ze střídače pomocí knihovny `goodwe`
3. Odesílá data do Home Assistant přes REST API

### Instalace

```bash
# 1. Nainstaluj goodwe knihovnu
pip3 install goodwe

# 2. Spusť bridge manuálně (pro test)
python3 goodwe_bridge.py

# 3. Pro automatický start při bootu (Linux):
sudo cp goodwe-bridge.service /etc/systemd/system/
sudo systemctl enable goodwe-bridge
sudo systemctl start goodwe-bridge
sudo systemctl status goodwe-bridge

# 4. Pro automatický start při bootu (macOS):
# Vytvoř LaunchAgent v ~/Library/LaunchAgents/
```

### Vytvořené sensory v Home Assistant

Bridge vytváří následující sensory:

#### Výroba
- `sensor.goodwe_pv_power` - Aktuální výkon FVE (W)
- `sensor.goodwe_pv1_power` - Výkon PV1 string (W)
- `sensor.goodwe_pv2_power` - Výkon PV2 string (W)
- `sensor.goodwe_today_generation` - Dnešní výroba (kWh)
- `sensor.goodwe_total_generation` - Celková výroba (kWh)

#### Síť
- `sensor.goodwe_grid_power` - Výkon do/ze sítě (W)
- `sensor.goodwe_today_export` - Dnešní export do sítě (kWh)
- `sensor.goodwe_total_export` - Celkový export (kWh)
- `sensor.goodwe_today_import` - Dnešní import ze sítě (kWh)
- `sensor.goodwe_total_import` - Celkový import (kWh)

#### Spotřeba
- `sensor.goodwe_house_consumption` - Spotřeba domu (W)

#### Baterie
- `sensor.goodwe_battery_soc` - Stav nabití baterie (%)
- `sensor.goodwe_battery_power` - Výkon baterie (W, - = nabíjení, + = vybíjení)

#### Ostatní
- `sensor.goodwe_inverter_temperature` - Teplota střídače (°C)

### Použití v Home Assistant

Po spuštění bridge můžeš sensory použít v:

#### Energy Dashboard
```yaml
# Configuration -> Energy
# Grid consumption: sensor.goodwe_total_import
# Grid production: sensor.goodwe_total_export
# Solar production: sensor.goodwe_total_generation
```

#### Lovelace Card
```yaml
type: entities
title: Solární Elektrárna
entities:
  - entity: sensor.goodwe_pv_power
  - entity: sensor.goodwe_house_consumption
  - entity: sensor.goodwe_battery_soc
  - entity: sensor.goodwe_grid_power
  - entity: sensor.goodwe_today_generation
```

#### Automation
```yaml
automation:
  - alias: "Notifikace - Nízká baterie"
    trigger:
      - platform: numeric_state
        entity_id: sensor.goodwe_battery_soc
        below: 10
    action:
      - service: notify.mobile_app
        data:
          message: "Baterie má pouze {{ states('sensor.goodwe_battery_soc') }}%"
```

### Monitoring

```bash
# Zobrazit logy bridge
tail -f /var/log/syslog | grep goodwe-bridge

# Nebo pro systemd
journalctl -u goodwe-bridge -f

# Zkontrolovat běžící proces
ps aux | grep goodwe_bridge

# Zkontrolovat sensor v HA
curl http://homeassistant.local:8123/api/states/sensor.goodwe_pv_power \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Alternativní řešení (pokud by bridge nefungoval)

1. **MQTT Bridge**: Publikovat data do MQTT brokeru, který HA již používá
2. **SEMS Portal API**: Použít cloud API (vyžaduje Power Station ID)
3. **Custom Integration**: Vytvořit vlastní HA integraci s proxy serverem
4. **Opravit síť**: Zjistit proč HA server nemůže komunikovat se střídačem

## Diagnostika síťového problému

```bash
# Z HA serveru
ssh hassio@homeassistant.local

# Test ping
ping 192.168.0.198

# Test UDP
python3 -c 'import socket; sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); sock.settimeout(5); sock.sendto(bytes.fromhex("AA55C07F0102000241"), ("192.168.0.198", 8899)); data, addr = sock.recvfrom(1024); print(f"OK: {addr}")'

# Zkontrolovat firewall
iptables -L -n
```

## Poznámky

- Bridge aktualizuje data každých 30 sekund
- GoodWe knihovna podporuje retry mechanismus pro spolehlivost
- Všechny sensory mají správné `device_class` pro Energy Dashboard
- Sensory jsou perzistentní v Home Assistant
