#!/usr/bin/env python3
"""
GoodWe to Home Assistant Bridge
Periodically reads data from GoodWe inverter and updates Home Assistant sensors
"""
import asyncio
import goodwe
import requests
import time
from datetime import datetime
import logging

# Configuration
HA_URL = "http://homeassistant.local:8123"
HA_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiI0MDcyZmY2MGM2NjQ0ZWUxODY3MTBiMTQ1OWRhNTI0YiIsImlhdCI6MTc2MjQ5OTQ2MCwiZXhwIjoyMDc3ODU5NDYwfQ.Ui-aLzFstt_W-ZFLUqS-3JnEXuHYqz7RtWR7jk1kra0"
INVERTER_IP = "192.168.0.198"
UPDATE_INTERVAL = 30  # seconds

# Logging setup
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def send_to_ha(entity_id: str, state: float, attributes: dict) -> bool:
    """Send sensor state to Home Assistant via REST API"""
    url = f"{HA_URL}/api/states/{entity_id}"
    headers = {
        "Authorization": f"Bearer {HA_TOKEN}",
        "Content-Type": "application/json"
    }

    payload = {
        "state": str(state),
        "attributes": attributes
    }

    try:
        response = requests.post(url, json=payload, headers=headers, timeout=5)
        return response.status_code in [200, 201]
    except Exception as e:
        logger.error(f"Error sending {entity_id} to HA: {e}")
        return False

async def read_and_update():
    """Read from inverter and update Home Assistant sensors"""
    try:
        # Connect to inverter
        inverter = await goodwe.connect(INVERTER_IP)
        logger.info(f"Connected to {inverter.model_name} (SN: {inverter.serial_number})")

        # Read runtime data
        runtime_data = await inverter.read_runtime_data()

        # Define sensors to update
        sensors = {
            "sensor.goodwe_pv_power": {
                "value": runtime_data.get('ppv', 0),
                "attrs": {
                    "unit_of_measurement": "W",
                    "friendly_name": "GoodWe PV Power",
                    "device_class": "power",
                    "icon": "mdi:solar-power"
                }
            },
            "sensor.goodwe_pv1_power": {
                "value": runtime_data.get('ppv1', 0),
                "attrs": {
                    "unit_of_measurement": "W",
                    "friendly_name": "GoodWe PV1 Power",
                    "device_class": "power",
                    "voltage": runtime_data.get('vpv1', 0),
                    "current": runtime_data.get('ipv1', 0)
                }
            },
            "sensor.goodwe_pv2_power": {
                "value": runtime_data.get('ppv2', 0),
                "attrs": {
                    "unit_of_measurement": "W",
                    "friendly_name": "GoodWe PV2 Power",
                    "device_class": "power",
                    "voltage": runtime_data.get('vpv2', 0),
                    "current": runtime_data.get('ipv2', 0)
                }
            },
            "sensor.goodwe_today_generation": {
                "value": runtime_data.get('e_day', 0),
                "attrs": {
                    "unit_of_measurement": "kWh",
                    "friendly_name": "GoodWe Today Generation",
                    "device_class": "energy",
                    "state_class": "total_increasing",
                    "icon": "mdi:solar-power"
                }
            },
            "sensor.goodwe_total_generation": {
                "value": runtime_data.get('e_total', 0),
                "attrs": {
                    "unit_of_measurement": "kWh",
                    "friendly_name": "GoodWe Total Generation",
                    "device_class": "energy",
                    "state_class": "total_increasing",
                    "icon": "mdi:counter"
                }
            },
            "sensor.goodwe_grid_power": {
                "value": runtime_data.get('active_power', 0),
                "attrs": {
                    "unit_of_measurement": "W",
                    "friendly_name": "GoodWe Grid Power",
                    "device_class": "power",
                    "icon": "mdi:transmission-tower"
                }
            },
            "sensor.goodwe_house_consumption": {
                "value": runtime_data.get('house_consumption', 0),
                "attrs": {
                    "unit_of_measurement": "W",
                    "friendly_name": "GoodWe House Consumption",
                    "device_class": "power",
                    "icon": "mdi:home-lightning-bolt"
                }
            },
            "sensor.goodwe_battery_soc": {
                "value": runtime_data.get('battery_soc', 0),
                "attrs": {
                    "unit_of_measurement": "%",
                    "friendly_name": "GoodWe Battery SOC",
                    "device_class": "battery",
                    "icon": "mdi:battery"
                }
            },
            "sensor.goodwe_battery_power": {
                "value": runtime_data.get('pbat', 0),
                "attrs": {
                    "unit_of_measurement": "W",
                    "friendly_name": "GoodWe Battery Power",
                    "device_class": "power",
                    "voltage": runtime_data.get('vbat', 0),
                    "current": runtime_data.get('ibat', 0),
                    "temperature": runtime_data.get('battery_temperature', 0)
                }
            },
            "sensor.goodwe_today_export": {
                "value": runtime_data.get('e_day_exp', 0),
                "attrs": {
                    "unit_of_measurement": "kWh",
                    "friendly_name": "GoodWe Today Export",
                    "device_class": "energy",
                    "state_class": "total_increasing"
                }
            },
            "sensor.goodwe_total_export": {
                "value": runtime_data.get('e_total_exp', 0),
                "attrs": {
                    "unit_of_measurement": "kWh",
                    "friendly_name": "GoodWe Total Export",
                    "device_class": "energy",
                    "state_class": "total_increasing"
                }
            },
            "sensor.goodwe_today_import": {
                "value": runtime_data.get('e_day_imp', 0),
                "attrs": {
                    "unit_of_measurement": "kWh",
                    "friendly_name": "GoodWe Today Import",
                    "device_class": "energy",
                    "state_class": "total_increasing"
                }
            },
            "sensor.goodwe_total_import": {
                "value": runtime_data.get('e_total_imp', 0),
                "attrs": {
                    "unit_of_measurement": "kWh",
                    "friendly_name": "GoodWe Total Import",
                    "device_class": "energy",
                    "state_class": "total_increasing"
                }
            },
            "sensor.goodwe_inverter_temperature": {
                "value": runtime_data.get('temperature_air', 0),
                "attrs": {
                    "unit_of_measurement": "°C",
                    "friendly_name": "GoodWe Inverter Temperature",
                    "device_class": "temperature"
                }
            }
        }

        # Send all sensors to HA
        success_count = 0
        for entity_id, data in sensors.items():
            if send_to_ha(entity_id, data['value'], data['attrs']):
                success_count += 1
            else:
                logger.warning(f"Failed to update {entity_id}")

        logger.info(f"Updated {success_count}/{len(sensors)} sensors successfully")

    except Exception as e:
        logger.error(f"Error reading from inverter: {e}", exc_info=True)

async def main():
    """Main loop"""
    logger.info("=" * 60)
    logger.info("GoodWe to Home Assistant Bridge")
    logger.info("=" * 60)
    logger.info(f"Inverter IP: {INVERTER_IP}")
    logger.info(f"Home Assistant: {HA_URL}")
    logger.info(f"Update interval: {UPDATE_INTERVAL}s")
    logger.info("=" * 60)

    while True:
        try:
            await read_and_update()
        except Exception as e:
            logger.error(f"Unexpected error in main loop: {e}", exc_info=True)

        await asyncio.sleep(UPDATE_INTERVAL)

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Stopping bridge... Goodbye!")
