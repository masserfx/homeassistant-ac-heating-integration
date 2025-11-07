"""Climate platform for AC Heating Heat Pump."""
from __future__ import annotations

from typing import Any

from pymodbus.exceptions import ModbusException

from homeassistant.components.climate import (
    ClimateEntity,
    ClimateEntityFeature,
    HVACMode,
)
from homeassistant.config_entries import ConfigEntry
from homeassistant.const import ATTR_TEMPERATURE, UnitOfTemperature
from homeassistant.core import HomeAssistant
from homeassistant.helpers.entity_platform import AddEntitiesCallback
from homeassistant.helpers.update_coordinator import CoordinatorEntity

from . import ACHeatingDataUpdateCoordinator
from .const import DOMAIN


async def async_setup_entry(
    hass: HomeAssistant, entry: ConfigEntry, async_add_entities: AddEntitiesCallback
) -> None:
    """Set up AC Heating climate entities."""
    coordinator: ACHeatingDataUpdateCoordinator = hass.data[DOMAIN][entry.entry_id]

    entities = []
    # Vytvoříme climate entity pro prvních 6 topných okruhů
    for i in range(1, 7):
        entities.append(ACHeatingClimate(coordinator, i))

    async_add_entities(entities)


class ACHeatingClimate(CoordinatorEntity, ClimateEntity):
    """AC Heating Climate entity."""

    _attr_temperature_unit = UnitOfTemperature.CELSIUS
    _attr_supported_features = ClimateEntityFeature.TARGET_TEMPERATURE
    _attr_hvac_modes = [HVACMode.HEAT, HVACMode.OFF]

    def __init__(self, coordinator: ACHeatingDataUpdateCoordinator, circuit_number: int) -> None:
        """Initialize the climate entity."""
        super().__init__(coordinator)
        self._circuit_number = circuit_number
        self._attr_name = f"AC Heating Topný okruh {circuit_number}"
        self._attr_unique_id = f"ac_heating_climate_{circuit_number}"

    @property
    def current_temperature(self) -> float | None:
        """Return the current temperature."""
        return self.coordinator.data.get(f"heating_circuit_{self._circuit_number}_room_temp")

    @property
    def target_temperature(self) -> float | None:
        """Return the temperature we try to reach."""
        return self.coordinator.data.get(f"heating_circuit_{self._circuit_number}_target_temp")

    @property
    def hvac_mode(self) -> HVACMode:
        """Return current operation mode."""
        enabled = self.coordinator.data.get(f"heating_circuit_{self._circuit_number}_enabled", False)
        return HVACMode.HEAT if enabled else HVACMode.OFF

    @property
    def hvac_action(self) -> str | None:
        """Return the current running hvac operation."""
        active = self.coordinator.data.get(f"heating_circuit_{self._circuit_number}_active", False)
        if active:
            return "heating"
        return "idle"

    async def async_set_temperature(self, **kwargs: Any) -> None:
        """Set new target temperature."""
        if (temperature := kwargs.get(ATTR_TEMPERATURE)) is None:
            return

        # Vypočítat adresu registru: topný okruh 1 = adresa 16, okruh 2 = 17, atd.
        register_address = 15 + self._circuit_number

        def write_temperature():
            # Teplota se násobí 100 (podle manuálu)
            value = int(temperature * 100)
            result = self.coordinator.client.write_register(
                address=register_address, value=value
            )
            if result.isError():
                raise ModbusException(f"Failed to write temperature: {result}")

        await self.hass.async_add_executor_job(write_temperature)
        await self.coordinator.async_request_refresh()

    async def async_set_hvac_mode(self, hvac_mode: HVACMode) -> None:
        """Set new target hvac mode."""
        # Coil adresa pro topný okruh: okruh 1 = coil 1, okruh 2 = coil 2, atd.
        coil_address = self._circuit_number

        def write_mode():
            value = hvac_mode == HVACMode.HEAT
            result = self.coordinator.client.write_coil(address=coil_address, value=value)
            if result.isError():
                raise ModbusException(f"Failed to write HVAC mode: {result}")

        await self.hass.async_add_executor_job(write_mode)
        await self.coordinator.async_request_refresh()
