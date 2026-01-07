"""
Open Weather API Client
Fetches wind direction and speed from OpenWeather API
"""

import requests
import logging
from typing import Dict, Optional
from datetime import datetime

logger = logging.getLogger(__name__)


class WeatherClient:
    """Client for fetching weather data from OpenWeather API"""
    
    BASE_URL = "https://api.openweathermap.org/data/2.5/weather"
    
    def __init__(self, api_key: str, latitude: float, longitude: float, 
                 units: str = "metric"):
        """
        Initialize Weather Client
        
        Args:
            api_key: OpenWeather API key
            latitude: Location latitude
            longitude: Location longitude
            units: Temperature units ('metric', 'imperial', 'kelvin')
        """
        self.api_key = api_key
        self.latitude = latitude
        self.longitude = longitude
        self.units = units
        self.last_fetch_time = None
        self.last_wind_direction = None
    
    def get_wind_direction(self) -> Optional[float]:
        """
        Fetch current wind direction from OpenWeather API
        
        Returns:
            Wind direction in degrees (0-360) where:
            - 0° = North
            - 90° = East
            - 180° = South
            - 270° = West
            Returns None if API call fails
        """
        try:
            params = {
                'lat': self.latitude,
                'lon': self.longitude,
                'appid': self.api_key,
                'units': self.units
            }
            
            response = requests.get(self.BASE_URL, params=params, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            wind_direction = data.get('wind', {}).get('deg')
            
            if wind_direction is not None:
                self.last_fetch_time = datetime.now()
                self.last_wind_direction = wind_direction
                logger.info(f"Wind direction fetched: {wind_direction}°")
                return wind_direction
            else:
                logger.warning("Wind direction not available in API response")
                return None
                
        except requests.exceptions.Timeout:
            logger.error("API request timed out")
            return None
        except requests.exceptions.HTTPError as e:
            logger.error(f"HTTP error occurred: {e}")
            return None
        except requests.exceptions.RequestException as e:
            logger.error(f"Error fetching weather data: {e}")
            return None
        except ValueError as e:
            logger.error(f"Error parsing JSON response: {e}")
            return None
    
    def get_full_weather(self) -> Optional[Dict]:
        """
        Fetch full weather data including wind information
        
        Returns:
            Dictionary with weather data or None if API call fails
        """
        try:
            params = {
                'lat': self.latitude,
                'lon': self.longitude,
                'appid': self.api_key,
                'units': self.units
            }
            
            response = requests.get(self.BASE_URL, params=params, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            logger.info(f"Weather data fetched for {data.get('name', 'Unknown location')}")
            
            return {
                'wind_direction': data.get('wind', {}).get('deg'),
                'wind_speed': data.get('wind', {}).get('speed'),
                'temperature': data.get('main', {}).get('temp'),
                'humidity': data.get('main', {}).get('humidity'),
                'description': data.get('weather', [{}])[0].get('description'),
                'timestamp': datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error fetching weather data: {e}")
            return None
