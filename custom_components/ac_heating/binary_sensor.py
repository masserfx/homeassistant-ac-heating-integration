"""Binary sensor platform for AC Heating Heat Pump."""
from __future__ import annotations

from homeassistant.components.binary_sensor import (
    BinarySensorDeviceClass,
    BinarySensorEntity,
)
from homeassistant.config_entries import ConfigEntry
from homeassistant.core import HomeAssistant
from homeassistant.helpers.entity_platform import AddEntitiesCallback
from homeassistant.helpers.update_coordinator import CoordinatorEntity

from . import ACHeatingDataUpdateCoordinator
from .const import DOMAIN


async def async_setup_entry(
    hass: HomeAssistant, entry: ConfigEntry, async_add_entities: AddEntitiesCallback
) -> None:
    """Set up AC Heating binary sensors."""
    coordinator: ACHeatingDataUpdateCoordinator = hass.data[DOMAIN][entry.entry_id]

    entities = [
        # Hlavní stavy
        ACHeatingBinarySensor(coordinator, "main_switch", "Hlavní vypínač", BinarySensorDeviceClass.POWER),
        ACHeatingBinarySensor(coordinator, "error", "Chyba", BinarySensorDeviceClass.PROBLEM),
        ACHeatingBinarySensor(coordinator, "error_noncritical", "Chyba nekritická", BinarySensorDeviceClass.PROBLEM),
        ACHeatingBinarySensor(coordinator, "error_critical", "Chyba kritická", BinarySensorDeviceClass.PROBLEM),

        # TUV stavy
        ACHeatingBinarySensor(coordinator, "tuv1_enabled", "TUV 1 - Povolena", BinarySensorDeviceClass.RUNNING),
        ACHeatingBinarySensor(coordinator, "tuv1_active", "TUV 1 - Aktivní", BinarySensorDeviceClass.RUNNING),
    ]

    # Topné okruhy stavy (prvních 6)
    for i in range(1, 7):
        entities.extend([
            ACHeatingBinarySensor(coordinator, f"heating_circuit_{i}_enabled", f"Topný okruh {i} - Povolen", BinarySensorDeviceClass.RUNNING),
            ACHeatingBinarySensor(coordinator, f"heating_circuit_{i}_active", f"Topný okruh {i} - Aktivní", BinarySensorDeviceClass.RUNNING),
        ])

    async_add_entities(entities)


class ACHeatingBinarySensor(CoordinatorEntity, BinarySensorEntity):
    """AC Heating Binary Sensor."""

    def __init__(
        self,
        coordinator: ACHeatingDataUpdateCoordinator,
        data_key: str,
        name: str,
        device_class: BinarySensorDeviceClass | None = None,
    ) -> None:
        """Initialize the binary sensor."""
        super().__init__(coordinator)
        self._data_key = data_key
        self._attr_name = f"AC Heating {name}"
        self._attr_unique_id = f"ac_heating_{data_key}"
        self._attr_device_class = device_class

    @property
    def is_on(self):
        """Return true if the binary sensor is on."""
        return self.coordinator.data.get(self._data_key, False)

    @property
    def available(self) -> bool:
        """Return if entity is available."""
        return (
            self.coordinator.last_update_success
            and self._data_key in self.coordinator.data
        )
