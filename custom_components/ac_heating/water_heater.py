"""Water heater platform for AC Heating Heat Pump."""
from __future__ import annotations

from typing import Any

from pymodbus.exceptions import ModbusException

from homeassistant.components.water_heater import (
    WaterHeaterEntity,
    WaterHeaterEntityFeature,
)
from homeassistant.config_entries import ConfigEntry
from homeassistant.const import ATTR_TEMPERATURE, UnitOfTemperature, STATE_ON, STATE_OFF
from homeassistant.core import HomeAssistant
from homeassistant.helpers.entity_platform import AddEntitiesCallback
from homeassistant.helpers.update_coordinator import CoordinatorEntity

from . import ACHeatingDataUpdateCoordinator
from .const import DOMAIN


async def async_setup_entry(
    hass: HomeAssistant, entry: ConfigEntry, async_add_entities: AddEntitiesCallback
) -> None:
    """Set up AC Heating water heater entities."""
    coordinator: ACHeatingDataUpdateCoordinator = hass.data[DOMAIN][entry.entry_id]

    entities = [
        ACHeatingWaterHeater(coordinator, 1),
    ]

    async_add_entities(entities)


class ACHeatingWaterHeater(CoordinatorEntity, WaterHeaterEntity):
    """AC Heating Water Heater entity."""

    _attr_temperature_unit = UnitOfTemperature.CELSIUS
    _attr_supported_features = WaterHeaterEntityFeature.TARGET_TEMPERATURE | WaterHeaterEntityFeature.ON_OFF
    _attr_operation_list = [STATE_ON, STATE_OFF]

    def __init__(self, coordinator: ACHeatingDataUpdateCoordinator, tuv_number: int) -> None:
        """Initialize the water heater entity."""
        super().__init__(coordinator)
        self._tuv_number = tuv_number
        self._attr_name = f"AC Heating TUV {tuv_number}"
        self._attr_unique_id = f"ac_heating_water_heater_{tuv_number}"

    @property
    def current_temperature(self) -> float | None:
        """Return the current temperature."""
        return self.coordinator.data.get(f"tuv{self._tuv_number}_actual_temp")

    @property
    def target_temperature(self) -> float | None:
        """Return the temperature we try to reach."""
        return self.coordinator.data.get(f"tuv{self._tuv_number}_max_temp")

    @property
    def min_temp(self) -> float:
        """Return the minimum temperature."""
        return self.coordinator.data.get(f"tuv{self._tuv_number}_min_temp", 30.0)

    @property
    def max_temp(self) -> float:
        """Return the maximum temperature."""
        return 65.0

    @property
    def current_operation(self) -> str:
        """Return current operation."""
        enabled = self.coordinator.data.get(f"tuv{self._tuv_number}_enabled", False)
        return STATE_ON if enabled else STATE_OFF

    async def async_set_temperature(self, **kwargs: Any) -> None:
        """Set new target temperature."""
        if (temperature := kwargs.get(ATTR_TEMPERATURE)) is None:
            return

        # TUV 1 max teplota = registr 88
        register_address = 87 + self._tuv_number

        def write_temperature():
            value = int(temperature * 100)
            result = self.coordinator.client.write_register(
                address=register_address, value=value
            )
            if result.isError():
                raise ModbusException(f"Failed to write temperature: {result}")

        await self.hass.async_add_executor_job(write_temperature)
        await self.coordinator.async_request_refresh()

    async def async_turn_on(self, **kwargs: Any) -> None:
        """Turn on the water heater."""
        # TUV 1 povolení = coil 25
        coil_address = 24 + self._tuv_number

        def write_on():
            result = self.coordinator.client.write_coil(address=coil_address, value=True)
            if result.isError():
                raise ModbusException(f"Failed to turn on: {result}")

        await self.hass.async_add_executor_job(write_on)
        await self.coordinator.async_request_refresh()

    async def async_turn_off(self, **kwargs: Any) -> None:
        """Turn off the water heater."""
        # TUV 1 povolení = coil 25
        coil_address = 24 + self._tuv_number

        def write_off():
            result = self.coordinator.client.write_coil(address=coil_address, value=False)
            if result.isError():
                raise ModbusException(f"Failed to turn off: {result}")

        await self.hass.async_add_executor_job(write_off)
        await self.coordinator.async_request_refresh()
