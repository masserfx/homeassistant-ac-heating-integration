"""AC Heating Heat Pump integration for Home Assistant."""
from __future__ import annotations

import logging
from datetime import timedelta

from pymodbus.client import ModbusTcpClient
from pymodbus.exceptions import ModbusException

from homeassistant.config_entries import ConfigEntry
from homeassistant.const import CONF_HOST, CONF_PORT, CONF_SCAN_INTERVAL, Platform
from homeassistant.core import HomeAssistant
from homeassistant.exceptions import ConfigEntryNotReady
from homeassistant.helpers.update_coordinator import DataUpdateCoordinator, UpdateFailed

_LOGGER = logging.getLogger(__name__)

DOMAIN = "ac_heating"
PLATFORMS = [Platform.SENSOR, Platform.CLIMATE, Platform.WATER_HEATER, Platform.BINARY_SENSOR]

DEFAULT_SCAN_INTERVAL = 30


async def async_setup_entry(hass: HomeAssistant, entry: ConfigEntry) -> bool:
    """Set up AC Heating Heat Pump from a config entry."""
    host = entry.data[CONF_HOST]
    port = entry.data.get(CONF_PORT, 502)
    scan_interval = entry.data.get(CONF_SCAN_INTERVAL, DEFAULT_SCAN_INTERVAL)

    coordinator = ACHeatingDataUpdateCoordinator(
        hass, host, port, timedelta(seconds=scan_interval)
    )

    await coordinator.async_config_entry_first_refresh()

    hass.data.setdefault(DOMAIN, {})
    hass.data[DOMAIN][entry.entry_id] = coordinator

    await hass.config_entries.async_forward_entry_setups(entry, PLATFORMS)

    return True


async def async_unload_entry(hass: HomeAssistant, entry: ConfigEntry) -> bool:
    """Unload a config entry."""
    if unload_ok := await hass.config_entries.async_unload_platforms(entry, PLATFORMS):
        hass.data[DOMAIN].pop(entry.entry_id)

    return unload_ok


class ACHeatingDataUpdateCoordinator(DataUpdateCoordinator):
    """Class to manage fetching AC Heating data."""

    def __init__(
        self, hass: HomeAssistant, host: str, port: int, update_interval: timedelta
    ) -> None:
        """Initialize."""
        self.host = host
        self.port = port
        self.client = None

        super().__init__(
            hass,
            _LOGGER,
            name=DOMAIN,
            update_interval=update_interval,
        )

    async def _async_update_data(self):
        """Fetch data from AC Heating Heat Pump."""
        try:
            return await self.hass.async_add_executor_job(self._fetch_data)
        except ModbusException as err:
            raise UpdateFailed(f"Error communicating with AC Heating: {err}") from err

    def _fetch_data(self):
        """Fetch data from Modbus TCP."""
        if self.client is None:
            self.client = ModbusTcpClient(self.host, port=self.port, timeout=5)
            self.client.connect()

        if not self.client.connected:
            self.client.connect()

        data = {}

        try:
            # Základní hodnoty (registry 0-15)
            result = self.client.read_holding_registers(address=0, count=16)
            if not result.isError():
                data["outdoor_temp"] = result.registers[0] / 100
                data["water_temp_actual"] = result.registers[1] / 100
                data["water_temp_target"] = result.registers[2] / 100
                data["system_power"] = result.registers[3]
                # Topné okruhy 1-12
                for i in range(12):
                    data[f"heating_circuit_{i+1}_room_temp"] = result.registers[4 + i] / 100

            # Požadované teploty topných okruhů (registry 16-27)
            result = self.client.read_holding_registers(address=16, count=12)
            if not result.isError():
                for i in range(12):
                    data[f"heating_circuit_{i+1}_target_temp"] = result.registers[i] / 100

            # Teploty topné vody (registry 28-39)
            result = self.client.read_holding_registers(address=28, count=12)
            if not result.isError():
                for i in range(12):
                    data[f"heating_circuit_{i+1}_water_temp"] = result.registers[i] / 100

            # TUV (registry 88-93)
            result = self.client.read_holding_registers(address=88, count=6)
            if not result.isError():
                data["tuv1_max_temp"] = result.registers[0] / 100
                data["tuv2_max_temp"] = result.registers[1] / 100
                data["tuv1_min_temp"] = result.registers[2] / 100
                data["tuv2_min_temp"] = result.registers[3] / 100
                data["tuv1_actual_temp"] = result.registers[4] / 100
                data["tuv2_actual_temp"] = result.registers[5] / 100

            # Teplota zpátečky (registry 284-285)
            result = self.client.read_holding_registers(address=284, count=2)
            if not result.isError():
                data["return_temp"] = result.registers[0] / 100
                data["return_temp_tuv"] = result.registers[1] / 100

            # Coils - stavy
            result = self.client.read_coils(address=0, count=90)
            if not result.isError():
                data["main_switch"] = result.bits[0]
                data["error"] = result.bits[33]
                data["error_noncritical"] = result.bits[34]
                data["error_critical"] = result.bits[35]

                # Topné okruhy - povolení a aktivní
                for i in range(12):
                    data[f"heating_circuit_{i+1}_enabled"] = result.bits[1 + i]
                    data[f"heating_circuit_{i+1}_active"] = result.bits[13 + i]

                # TUV
                data["tuv1_enabled"] = result.bits[25]
                data["tuv2_enabled"] = result.bits[26]
                data["tuv1_active"] = result.bits[27]
                data["tuv2_active"] = result.bits[28]

        except Exception as err:
            _LOGGER.error(f"Error fetching data: {err}")
            raise UpdateFailed(f"Error fetching data: {err}") from err

        return data
