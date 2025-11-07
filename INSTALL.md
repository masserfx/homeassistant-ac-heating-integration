# Instalační průvodce

Tento průvodce vás provede instalací 3 integrací pro Home Assistant:

- **AC Heating Heat Pump** (202 entit)
- **GoodWe Solar** (14 senzorů)
- **Czech Energy Spot Prices** (13 entit)

## 📦 Rychlý start

Vyber svou platformu a spusť instalační skript:

### 🐧 Linux

```bash
cd installers/linux
chmod +x install.sh
./install.sh
```

### 🍎 macOS

```bash
cd installers/macos
chmod +x install.sh
./install.sh
```

### 🪟 Windows

```powershell
cd installers\windows
PowerShell -ExecutionPolicy Bypass -File install.ps1
```

---

## 📋 Co instalační skripty dělají

### 1. Kontrola systému
- Detekce operačního systému
- Kontrola požadovaných nástrojů (SSH, Python)
- Automatická instalace chybějících závislostí

### 2. Konfigurace připojení
Instalátor se zeptá na:
- **Home Assistant adresa** (výchozí: homeassistant.local)
- **SSH metoda** (heslo nebo klíč)
- **SSH přihlašovací údaje**
- **GoodWe konfigurace** (volitelně)

### 3. Instalace integrací
- Zkopíruje `ac_heating` do `/config/custom_components/`
- Zkopíruje `cz_energy_spot_prices` do `/config/custom_components/`
- Nainstaluje GoodWe bridge (pokud zvoleno)

### 4. Výsledek
Po dokončení instalátor zobrazí návod na další kroky.

---

## 🔧 Požadavky

### Home Assistant
- Home Assistant Core 2024.1+
- SSH přístup (některý z těchto addonů):
  - **Advanced SSH & Web Terminal** (user: hassio, port: 22)
  - **Terminal & SSH** (user: root, port: 22222)

### Vaš počítač

#### Linux
- Bash shell
- SSH klient (předinstalován)
- Python 3.8+ (pro GoodWe bridge)
- sshpass (automaticky se nainstaluje, pokud chybí)

#### macOS
- Bash shell (předinstalován)
- SSH klient (předinstalován)
- Homebrew (automaticky se nainstaluje, pokud chybí)
- Python 3.8+ (pro GoodWe bridge)

#### Windows
- PowerShell 5.1+
- OpenSSH Client (Windows 10 1809+)
- Python 3.8+ (pro GoodWe bridge)

---

## 🚀 Podrobná instalace po platformách

### Linux - Krok za krokem

1. **Příprava**
   ```bash
   git clone <repository-url>
   cd ac_heating_integration/installers/linux
   chmod +x install.sh
   ```

2. **Spuštění**
   ```bash
   ./install.sh
   ```

3. **Konfigurace**
   - Zadej adresu HA (např. `homeassistant.local` nebo `192.168.1.100`)
   - Zvol SSH metodu:
     - **1 = Heslo**: Pro Advanced SSH & Web Terminal addon
     - **2 = SSH klíč**: Pro Terminal & SSH addon
   - Zadej přihlašovací údaje

4. **GoodWe (volitelně)**
   - Pokud máš GoodWe inverter, odpověz `y`
   - Zadej IP adresu inverteru
   - Zadej HA URL a API token

5. **Dokončení**
   - Restartuj Home Assistant
   - Přidej integrace v UI

### macOS - Krok za krokem

1. **Příprava**
   ```bash
   git clone <repository-url>
   cd ac_heating_integration/installers/macos
   chmod +x install.sh
   ```

2. **Spuštění**
   ```bash
   ./install.sh
   ```

   Instalátor automaticky:
   - Nainstaluje Homebrew (pokud chybí)
   - Nainstaluje sshpass přes Homebrew tap
   - Zkontroluje SSH připojení

3. **Konfigurace**
   Stejné jako u Linuxu (viz výše)

4. **GoodWe bridge jako LaunchAgent**
   Pokud instaluješ GoodWe bridge, vytvoří se:
   - `~/Library/HomeAssistantBridge/` (skripty)
   - `~/Library/LaunchAgents/com.homeassistant.goodwebridge.plist` (autostart)
   - `~/Library/Logs/goodwe-bridge.log` (logy)

   Kontrola stavu:
   ```bash
   launchctl list | grep goodwe
   tail -f ~/Library/Logs/goodwe-bridge.log
   ```

### Windows - Krok za krokem

1. **Příprava**
   - Stáhni repository (ZIP nebo git clone)
   - Otevři PowerShell jako Administrátor
   - Přejdi do složky: `cd ac_heating_integration\installers\windows`

2. **Spuštění**
   ```powershell
   PowerShell -ExecutionPolicy Bypass -File install.ps1
   ```

   Instalátor automaticky:
   - Nainstaluje OpenSSH Client (pokud chybí)
   - Zkontroluje Python

3. **Konfigurace**

   **Pokud máš SSH klíč:**
   - Instalátor zkopíruje soubory automaticky

   **Pokud máš jen heslo:**
   - Instalátor zobrazí manuální návod
   - Použij WinSCP nebo FileZilla k přenosu souborů

4. **WinSCP instalace (pro heslo)**

   a) Stáhni WinSCP: https://winscp.net/

   b) Připoj se:
   - Host: `homeassistant.local` (nebo IP)
   - User: `hassio` (nebo `root`)
   - Password: tvoje heslo
   - Port: 22

   c) Zkopíruj složky:
   - `custom_components\ac_heating` → `/config/custom_components/`
   - `custom_components\cz_energy_spot_prices` → `/config/custom_components/`

5. **GoodWe bridge**
   - Zkopíruj `goodwe_bridge.py` do `C:\HomeAssistant\`
   - Nastav proměnné v souboru
   - Vytvoř Task Scheduler task pro autostart

---

## 🔑 SSH Konfigurace

### Advanced SSH & Web Terminal Addon (doporučeno)

**Konfigurace:**
```yaml
authorized_keys: []
password: "tvoje_heslo"
username: hassio
```

**Připojení:**
- Host: `homeassistant.local`
- Port: `22`
- User: `hassio`
- Password: tvoje heslo

### Terminal & SSH Addon

**Konfigurace:**
```yaml
authorized_keys:
  - ssh-rsa AAAAB... your@email.com
password: ""
```

**Připojení:**
- Host: `homeassistant.local`
- Port: `22222` (nebo 22)
- User: `root`
- Auth: SSH klíč

---

## 📱 GoodWe Solar Bridge

### Co to je?
GoodWe bridge je Python skript, který:
- Čte data z GoodWe inverteru (UDP port 8899)
- Odesílá data do Home Assistant přes REST API
- Běží na tvém počítači (ne v HA)

### Proč bridge?
Home Assistant může mít problém s přímým připojením k inverteru přes firewally nebo VLAN. Bridge běží na tvém počítači, který má přístup k inverteru i k HA.

### Instalace

1. **Získej HA API Token**
   - Home Assistant → Profil → Long-Lived Access Tokens
   - Vytvoř nový token
   - Zkopíruj hodnotu

2. **Zjisti IP inverteru**
   ```bash
   # Linux/macOS:
   nmap -sn 192.168.0.0/24 | grep -i goodwe

   # Windows:
   arp -a | findstr /i "goodwe"
   ```

3. **Spusť instalátor**
   Instalační skripty se zeptají na GoodWe konfiguraci

4. **Ověř funkčnost**
   ```bash
   # Linux/macOS:
   systemctl --user status goodwe-bridge
   # nebo
   launchctl list | grep goodwe

   # Windows:
   # Zkontroluj Task Scheduler
   ```

### Manuální instalace

Pokud instalátor selže, můžeš nainstalovat ručně:

```bash
# 1. Instaluj závislosti
pip3 install goodwe requests

# 2. Zkopíruj goodwe_bridge.py
cp goodwe_bridge.py ~/goodwe_bridge.py

# 3. Nastav proměnné v souboru
nano ~/goodwe_bridge.py
# Změň: GOODWE_IP, HA_URL, HA_TOKEN

# 4. Spusť
python3 ~/goodwe_bridge.py &
```

---

## ✅ Po instalaci

### 1. Restartuj Home Assistant
```
Nastavení → Systém → Restartovat
```

Počkej 2-3 minuty na restart.

### 2. Přidej AC Heating Heat Pump

```
Nastavení → Zařízení a služby → Přidat integraci → "AC Heating"
```

Vyplň:
- **IP adresa**: `192.168.0.166` (nebo IP tvého čerpadla)
- **Port**: `502`
- **Interval aktualizace**: `30` sekund

**Výsledek**: 202 nových entit
- 140 senzorů (teploty, výkony, diagnostika)
- 48 binárních senzorů (stavy, alarmy)
- 12 climate (termostaty topných okruhů)
- 2 water heater (TUV ohřívače)

### 3. Přidej Czech Energy Spot Prices

```
Nastavení → Zařízení a služby → Přidat integraci → "Czech Energy Spot Prices"
```

Vyplň:
- **Komodita**: Elektřina
- **Jednotka**: kWh
- **Měna**: CZK

**Výsledek**: 13 nových entit
- Aktuální spotová cena
- Předpověď na 24h
- Min/Max denní ceny
- Binární senzor "Je levná elektřina?"

### 4. Ověř GoodWe senzory (pokud instalováno)

Přejdi do:
```
Vývojářské nástroje → Stavy → Filtr: "goodwe"
```

Měl bys vidět 14 senzorů s aktuálními hodnotami.

---

## 🛠️ Troubleshooting

### Problém: "Invalid handler specified"

**Příčina**: Špatně přenesené Python soubory nebo zastaralá třída v config_flow.py

**Řešení**:
```bash
# Připoj se přes SSH
ssh hassio@homeassistant.local

# Zkontroluj syntax
cd /config/custom_components/ac_heating
python3 -m py_compile config_flow.py

# Zkontroluj logy
tail -100 /config/home-assistant.log | grep -A 10 "ac_heating"
```

### Problém: "Cannot connect" (AC Heating)

**Příčina**: Modbus TCP připojení nefunguje

**Řešení**:
```bash
# Test Modbus připojení
python3 -c "from pymodbus.client import ModbusTcpClient; \
  c = ModbusTcpClient('192.168.0.166', 502); \
  print('OK' if c.connect() else 'FAIL')"
```

Zkontroluj:
- Je čerpadlo zapnuté?
- Je správná IP adresa?
- Je port 502 otevřený? (`telnet 192.168.0.166 502`)
- Není aktivní jiné Modbus připojení? (čerpadlo umožňuje jen jedno)

### Problém: SSH připojení selhalo

**Řešení**:

1. **Zkontroluj SSH addon**
   - Je spuštěný?
   - Běží na správném portu?

2. **Test připojení**
   ```bash
   # Linux/macOS:
   ping homeassistant.local
   ssh hassio@homeassistant.local

   # Windows:
   Test-Connection homeassistant.local
   ssh hassio@homeassistant.local
   ```

3. **Zkontroluj firewall**
   - Windows: Firewall → Povolené aplikace → OpenSSH
   - Linux: `sudo ufw allow 22/tcp`

### Problém: GoodWe bridge nepracuje

**Kontrola**:
```bash
# Linux:
systemctl --user status goodwe-bridge
journalctl --user -u goodwe-bridge -f

# macOS:
launchctl list | grep goodwe
tail -f ~/Library/Logs/goodwe-bridge.log

# Windows:
# Zkontroluj Task Scheduler
# Nebo spusť ručně v PowerShell
```

**Řešení**:
1. Zkontroluj, že inverter je dostupný:
   ```bash
   ping 192.168.0.198
   ```

2. Zkontroluj Python závislosti:
   ```bash
   pip3 show goodwe
   pip3 show requests
   ```

3. Spusť bridge ručně s debug výstupem:
   ```bash
   python3 ~/goodwe_bridge.py
   ```

### Problém: Spotové ceny neukazují data

**Řešení**:
```bash
# Test OTE API
curl "https://www.ote-cr.cz/cs/kratkodobe-trhy/elektrina/denni-trh/@@chart-data?report_date=$(date +%Y-%m-%d)"
```

Pokud API vrací data, zkontroluj logy HA:
```bash
tail -100 /config/home-assistant.log | grep -A 10 "cz_energy"
```

---

## 📚 Dodatečné zdroje

### Dokumentace
- **AC Heating Modbus**: `xCC_modbus-2.0.pdf` (v projektu)
- **GoodWe Library**: https://github.com/marcelblijleven/goodwe
- **CZ Spot Prices**: https://github.com/rnovacek/homeassistant_cz_energy_spot_prices

### Podpora
- **Issues**: Vytvořte issue na GitHubu
- **Email**: (pokud dostupný)
- **HA Community**: https://community.home-assistant.io/

### Aktualizace
```bash
git pull
cd installers/<your-platform>
./install.sh  # Přeinstaluje s novými verzemi
```

---

## 📄 Licence

MIT License - viz LICENSE soubor

---

**Úspěšnou instalaci! 🎉**

Pokud máš problémy, vytvoř issue na GitHubu s:
- Tvůj OS a verze
- Home Assistant verze
- Logy z instalace
- Chybová hláška
