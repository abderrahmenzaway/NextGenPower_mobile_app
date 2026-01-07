"""
Wind Turbine Control System
Main application that coordinates weather data fetching and turbine control
"""

import json
import logging
import time
import sys
from pathlib import Path
from datetime import datetime
from typing import Optional
from threading import Thread

from weather_client import WeatherClient
from servo_controller import ServoController


# Setup logging
def setup_logging(log_file: str = "logs/wind_turbine.log", 
                  log_level: str = "INFO") -> None:
    """Setup logging configuration"""
    log_path = Path(log_file)
    log_path.parent.mkdir(parents=True, exist_ok=True)
    
    logging.basicConfig(
        level=getattr(logging, log_level),
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )


logger = logging.getLogger(__name__)


def get_location_input() -> tuple:
    """
    Prompt user for location input
    
    Returns:
        Tuple of (latitude, longitude, city_name)
    """
    print("\n" + "="*60)
    print("WIND TURBINE CONTROL SYSTEM - LOCATION SETUP")
    print("="*60)

    # Get custom location
    print("\nEnter custom location:")
    
    while True:
        try:
            latitude = float(input("Latitude : ").strip())
            if -90 <= latitude <= 90:
                break
            print("❌ Latitude must be between -90 and 90")
        except ValueError:
            print("❌ Invalid input. Please enter a number.")
    
    while True:
        try:
            longitude = float(input("Longitude : ").strip())
            if -180 <= longitude <= 180:
                break
            print("❌ Longitude must be between -180 and 180")
        except ValueError:
            print("❌ Invalid input. Please enter a number.")
    
    city_name = input("City name : ").strip()
    if not city_name:
        city_name = f"{latitude}, {longitude}"
    
    print(f"\n✓ Location set: {city_name} ({latitude}°N, {longitude}°E)")
    return latitude, longitude, city_name


class WindTurbineController:
    """Main controller for wind turbine system"""
    
    def __init__(self, config_path: str = "config/config.json"):
        """
        Initialize Wind Turbine Controller
        
        Args:
            config_path: Path to configuration JSON file
        """
        self.config = self.load_config(config_path)
        
        # Setup logging
        setup_logging(
            self.config['logging']['log_file'],
            self.config['logging']['log_level']
        )
        
        # Initialize components
        self.weather_client = None
        self.servo_controller = None
        self.is_running = False
        self.last_wind_direction = None
        self.last_update_time = None
    
    @staticmethod
    def load_config(config_path: str) -> dict:
        """
        Load configuration from JSON file
        
        Args:
            config_path: Path to config.json
            
        Returns:
            Configuration dictionary
        """
        try:
            with open(config_path, 'r') as f:
                config = json.load(f)
            print(f"Configuration loaded from {config_path}")
            return config
        except FileNotFoundError:
            print(f"Error: Configuration file not found at {config_path}")
            sys.exit(1)
        except json.JSONDecodeError:
            print(f"Error: Invalid JSON in {config_path}")
            sys.exit(1)
    
    def initialize(self) -> bool:
        """
        Initialize weather client and servo controller
        
        Returns:
            True if initialization successful, False otherwise
        """
        try:
            # Initialize Weather Client
            weather_config = self.config['openweather']
            self.weather_client = WeatherClient(
                api_key=weather_config['api_key'],
                latitude=weather_config['latitude'],
                longitude=weather_config['longitude'],
                units=weather_config['units']
            )
            logger.info("Weather client initialized")
            
            # Initialize Servo Controller
            arduino_config = self.config['arduino']
            self.servo_controller = ServoController(
                port=arduino_config['port'],
                baudrate=arduino_config['baudrate'],
                timeout=arduino_config['timeout'],
                demo_mode=arduino_config.get('demo_mode', False)
            )
            
            if not self.servo_controller.connect():
                logger.error("Failed to connect to Arduino")
                return False
            
            # Test Arduino connection
            if not self.servo_controller.test_connection():
                logger.error("Arduino connection test failed")
                return False
            
            logger.info("System initialized successfully")
            return True
            
        except Exception as e:
            logger.error(f"Initialization error: {e}")
            return False
    
    def update_turbine_position(self) -> bool:
        """
        Fetch wind direction and update turbine position
        
        Returns:
            True if update successful, False otherwise
        """
        try:
            # Fetch wind direction from API
            wind_direction = self.weather_client.get_wind_direction()
            
            if wind_direction is None:
                logger.warning("Could not fetch wind direction")
                return False
            
            # Check if wind direction changed significantly (at least 5 degrees)
            if (self.last_wind_direction is not None and 
                abs(wind_direction - self.last_wind_direction) < 5):
                logger.debug(f"Wind direction unchanged: {wind_direction}°")
                return True
            
            # Convert wind direction to servo angle
            servo_angle = self.servo_controller.convert_wind_direction_to_angle(
                wind_direction
            )
            
            logger.info(f"Wind direction: {wind_direction}° → Servo angle: {servo_angle}°")
            
            # Set servo angle
            if self.servo_controller.set_angle(servo_angle):
                self.last_wind_direction = wind_direction
                self.last_update_time = datetime.now()
                
                # Log full weather data
                weather_data = self.weather_client.get_full_weather()
                if weather_data:
                    logger.info(
                        f"Weather: Wind {weather_data['wind_direction']}° "
                        f"@ {weather_data['wind_speed']} m/s, "
                        f"Temp: {weather_data['temperature']}°C, "
                        f"Humidity: {weather_data['humidity']}%"
                    )
                
                return True
            else:
                logger.error("Failed to set servo angle")
                return False
            
        except Exception as e:
            logger.error(f"Error updating turbine position: {e}")
            return False
    
    def run(self, interval_hours: Optional[int] = None) -> None:
        """
        Run the wind turbine controller in a loop
        
        Args:
            interval_hours: Update interval in hours (default from config)
        """
        if interval_hours is None:
            interval_hours = self.config['openweather']['update_interval_hours']
        
        interval_seconds = interval_hours * 3600
        
        self.is_running = True
        logger.info(f"Starting wind turbine controller (update every {interval_hours} hour(s))")
        
        try:
            # Initial update
            self.update_turbine_position()
            
            # Main loop
            while self.is_running:
                # Calculate time until next update
                time_until_next = self.calculate_time_until_next_update(interval_seconds)
                
                logger.info(
                    f"Next update in {time_until_next} seconds "
                    f"({time_until_next / 60:.1f} minutes)"
                )
                
                # Wait for next update
                time.sleep(min(60, time_until_next))  # Check every 60 seconds max
                
                # Check if it's time to update
                if self.calculate_time_until_next_update(interval_seconds) <= 0:
                    self.update_turbine_position()
        
        except KeyboardInterrupt:
            logger.info("Received interrupt signal")
        except Exception as e:
            logger.error(f"Unexpected error in main loop: {e}")
        finally:
            self.shutdown()
    
    def calculate_time_until_next_update(self, interval_seconds: int) -> int:
        """Calculate seconds until next scheduled update"""
        if self.last_update_time is None:
            return 0
        
        elapsed = (datetime.now() - self.last_update_time).total_seconds()
        time_remaining = interval_seconds - elapsed
        return max(0, int(time_remaining))
    
    def shutdown(self) -> None:
        """Gracefully shutdown the system"""
        logger.info("Shutting down wind turbine controller")
        self.is_running = False
        
        if self.servo_controller and self.servo_controller.is_connected:
            self.servo_controller.disconnect()
        
        logger.info("Shutdown complete")


def main():
    """Main entry point"""
    # Determine config path based on script location
    script_dir = Path(__file__).parent.parent
    config_path = script_dir / "config" / "config.json"
    
    # Get location input from user
    latitude, longitude, city_name = get_location_input()
    
    # Load and update configuration
    with open(config_path, 'r') as f:
        config = json.load(f)
    
    # Update location in config
    config['openweather']['latitude'] = latitude
    config['openweather']['longitude'] = longitude
    config['openweather']['city'] = city_name
    
    # Save updated config
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2)
    
    print(f"\n✓ Configuration updated and saved to {config_path}")
    print("="*60 + "\n")
    
    # Create controller
    controller = WindTurbineController(str(config_path))
    
    # Initialize system
    if not controller.initialize():
        logger.error("Failed to initialize system")
        return 1
    
    # Run the controller
    controller.run()
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
