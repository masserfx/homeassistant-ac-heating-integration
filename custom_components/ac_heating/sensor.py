"""Sensor platform for AC Heating Heat Pump."""
from __future__ import annotations

from homeassistant.components.sensor import (
    SensorDeviceClass,
    SensorEntity,
    SensorStateClass,
)
from homeassistant.config_entries import ConfigEntry
from homeassistant.const import PERCENTAGE, UnitOfTemperature
from homeassistant.core import HomeAssistant
from homeassistant.helpers.entity import EntityCategory
from homeassistant.helpers.entity_platform import AddEntitiesCallback
from homeassistant.helpers.update_coordinator import CoordinatorEntity

from . import ACHeatingDataUpdateCoordinator
from .const import DOMAIN


async def async_setup_entry(
    hass: HomeAssistant, entry: ConfigEntry, async_add_entities: AddEntitiesCallback
) -> None:
    """Set up AC Heating sensors."""
    coordinator: ACHeatingDataUpdateCoordinator = hass.data[DOMAIN][entry.entry_id]

    entities = [
        # Základní senzory
        ACHeatingSensor(coordinator, "outdoor_temp", "Venkovní teplota", UnitOfTemperature.CELSIUS, SensorDeviceClass.TEMPERATURE),
        ACHeatingSensor(coordinator, "water_temp_actual", "Aktuální teplota vody", UnitOfTemperature.CELSIUS, SensorDeviceClass.TEMPERATURE),
        ACHeatingSensor(coordinator, "water_temp_target", "Požadovaná teplota vody", UnitOfTemperature.CELSIUS, SensorDeviceClass.TEMPERATURE),
        ACHeatingSensor(coordinator, "system_power", "Výkon systému", PERCENTAGE, None),
        ACHeatingSensor(coordinator, "return_temp", "Teplota zpátečky", UnitOfTemperature.CELSIUS, SensorDeviceClass.TEMPERATURE),
        ACHeatingSensor(coordinator, "return_temp_tuv", "Teplota zpátečky TUV", UnitOfTemperature.CELSIUS, SensorDeviceClass.TEMPERATURE),

        # TUV senzory
        ACHeatingSensor(coordinator, "tuv1_actual_temp", "TUV 1 - Aktuální teplota", UnitOfTemperature.CELSIUS, SensorDeviceClass.TEMPERATURE),
        ACHeatingSensor(coordinator, "tuv1_max_temp", "TUV 1 - Max teplota", UnitOfTemperature.CELSIUS, SensorDeviceClass.TEMPERATURE, entity_category=EntityCategory.DIAGNOSTIC),
        ACHeatingSensor(coordinator, "tuv1_min_temp", "TUV 1 - Min teplota", UnitOfTemperature.CELSIUS, SensorDeviceClass.TEMPERATURE, entity_category=EntityCategory.DIAGNOSTIC),
    ]

    # Topné okruhy senzory (pouze prvních 6 pro začátek)
    for i in range(1, 7):
        entities.extend([
            ACHeatingSensor(coordinator, f"heating_circuit_{i}_room_temp", f"Topný okruh {i} - Teplota místnosti", UnitOfTemperature.CELSIUS, SensorDeviceClass.TEMPERATURE),
            ACHeatingSensor(coordinator, f"heating_circuit_{i}_target_temp", f"Topný okruh {i} - Cílová teplota", UnitOfTemperature.CELSIUS, SensorDeviceClass.TEMPERATURE),
            ACHeatingSensor(coordinator, f"heating_circuit_{i}_water_temp", f"Topný okruh {i} - Teplota topné vody", UnitOfTemperature.CELSIUS, SensorDeviceClass.TEMPERATURE),
        ])

    async_add_entities(entities)


class ACHeatingSensor(CoordinatorEntity, SensorEntity):
    """AC Heating Sensor."""

    def __init__(
        self,
        coordinator: ACHeatingDataUpdateCoordinator,
        data_key: str,
        name: str,
        unit: str | None,
        device_class: SensorDeviceClass | None = None,
        entity_category: EntityCategory | None = None
    ) -> None:
        """Initialize the sensor."""
        super().__init__(coordinator)
        self._data_key = data_key
        self._attr_name = f"AC Heating {name}"
        self._attr_unique_id = f"ac_heating_{data_key}"
        self._attr_native_unit_of_measurement = unit
        self._attr_device_class = device_class
        self._attr_state_class = SensorStateClass.MEASUREMENT if device_class == SensorDeviceClass.TEMPERATURE else None
        self._attr_entity_category = entity_category

    @property
    def native_value(self):
        """Return the state of the sensor."""
        return self.coordinator.data.get(self._data_key)

    @property
    def available(self) -> bool:
        """Return if entity is available."""
        return (
            self.coordinator.last_update_success
            and self._data_key in self.coordinator.data
        )
