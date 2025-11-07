# Přispívání k projektu

Děkujeme za zájem přispět k tomuto projektu! 🎉

## 📋 Jak přispět

### 1. Nahlášení chyby (Bug Report)

Pokud jsi našel chybu, vytvoř [nový issue](https://github.com/masserfx/homeassistant-ac-heating-integration/issues/new) s:

- **Popis problému**: Co se stalo vs. co jsi očekával
- **Kroky k reprodukci**: Jak chybu vyvolat
- **Prostředí**:
  - Home Assistant verze
  - OS (Linux/macOS/Windows + verze)
  - Verze integrace
- **Logy**: Relevantní chybové hlášky

**Příklad:**
```
**Problém:** AC Heating integrace se nenapojí na čerpadlo

**Kroky:**
1. Přidal jsem integraci přes UI
2. Zadal IP 192.168.1.100, port 502
3. Chyba: "Cannot connect"

**Prostředí:**
- HA 2024.11.1
- Linux Ubuntu 22.04
- Integrace v1.0.0

**Logy:**
[Paste logs here]
```

### 2. Návrh na vylepšení (Feature Request)

Pro návrhy nových funkcí vytvoř issue s:

- **Popis funkce**: Co by měla dělat
- **Use case**: Proč je to užitečné
- **Alternativy**: Jaké jiné řešení existuje

### 3. Pull Request

1. **Fork** repository
2. **Vytvoř branch** pro svou změnu:
   ```bash
   git checkout -b feature/nova-funkce
   ```
3. **Udělej změny** a commit:
   ```bash
   git commit -m "feat: Přidání nové funkce"
   ```
4. **Push** do svého forku:
   ```bash
   git push origin feature/nova-funkce
   ```
5. **Vytvoř Pull Request** na GitHub

#### Pravidla pro PR:

- ✅ Použij [Conventional Commits](https://www.conventionalcommits.org/)
- ✅ Piš jasné commit zprávy
- ✅ Testuj před odesláním
- ✅ Aktualizuj dokumentaci pokud potřeba

**Conventional Commits příklady:**
```
feat: Přidání podpory pro nové čerpadlo XYZ
fix: Oprava Modbus timeoutu
docs: Aktualizace instalačního návodu
refactor: Zlepšení error handlingu
test: Přidání testů pro config_flow
```

## 🏗️ Struktura projektu

```
homeassistant-ac-heating-integration/
├── custom_components/
│   ├── ac_heating/           # AC Heating integrace
│   │   ├── __init__.py       # Hlavní soubor
│   │   ├── config_flow.py    # UI konfigurace
│   │   ├── sensor.py         # Senzory
│   │   ├── climate.py        # Termostaty
│   │   └── ...
│   └── cz_energy_spot_prices/ # Spotové ceny
│
├── installers/
│   ├── linux/               # Linux instalátor
│   ├── macos/               # macOS instalátor
│   └── windows/             # Windows instalátor
│
├── goodwe_bridge.py         # GoodWe bridge
└── docs/                    # Dokumentace
```

## 🔧 Vývoj lokálně

### Testování AC Heating integrace

```bash
# 1. Zkopíruj do HA config
cp -r custom_components/ac_heating ~/.homeassistant/custom_components/

# 2. Restartuj HA
ha core restart

# 3. Sleduj logy
tail -f ~/.homeassistant/home-assistant.log | grep ac_heating
```

### Testování instalátorů

```bash
# Linux/macOS
cd installers/linux   # nebo macos
bash -x install.sh    # Debug mód

# Windows
cd installers\windows
PowerShell -ExecutionPolicy Bypass -File install.ps1 -Verbose
```

## 📝 Coding Style

### Python

- Použij **Black** formatter:
  ```bash
  pip install black
  black custom_components/
  ```

- Použij **type hints**:
  ```python
  def fetch_data(client: ModbusTcpClient) -> dict[str, Any]:
      ...
  ```

- Dokumentuj funkce:
  ```python
  def calculate_temperature(raw_value: int) -> float:
      """Convert raw Modbus value to temperature in Celsius.

      Args:
          raw_value: Raw register value (0-65535)

      Returns:
          Temperature in °C
      """
      return raw_value / 100.0
  ```

### Bash/Shell

- Použij **shellcheck**:
  ```bash
  shellcheck installers/linux/install.sh
  ```

- Cituj proměnné:
  ```bash
  # ✅ Správně
  echo "$VARIABLE"

  # ❌ Špatně
  echo $VARIABLE
  ```

## 🧪 Testování

### Před odesláním PR:

1. **Testuj integraci v HA**
   - Přidej integraci přes UI
   - Ověř všechny entity
   - Zkontroluj logy na chyby

2. **Testuj instalátor**
   - Spusť na čisté instalaci
   - Ověř všechny kroky
   - Testuj error handling

3. **Zkontroluj kód**
   ```bash
   # Python
   black --check custom_components/
   pylint custom_components/

   # Bash
   shellcheck installers/**/*.sh
   ```

## 🎯 Priority pro přispěvatele

### Vysoká priorita:

- 🐛 Opravy kritických chyb
- 📖 Vylepšení dokumentace
- 🌍 Překlady do dalších jazyků
- 🧪 Přidání testů

### Střední priorita:

- ✨ Nové funkce
- 🎨 UI vylepšení
- ⚡ Optimalizace výkonu

### Nízká priorita:

- 🎨 Kosmetické úpravy
- ♻️ Refaktoring

## 💬 Komunikace

- **Issues**: Pro bug reporty a feature requesty
- **Discussions**: Pro obecné dotazy a diskuzi
- **Pull Requests**: Pro code review

## 📄 Licence

Přispěním do tohoto projektu souhlasíš s tím, že tvůj kód bude pod [MIT License](LICENSE).

## 🙏 Uznání

Všichni přispěvatelé budou uvedeni v [CONTRIBUTORS.md](CONTRIBUTORS.md).

---

**Děkujeme za tvůj příspěvek! 🎉**
