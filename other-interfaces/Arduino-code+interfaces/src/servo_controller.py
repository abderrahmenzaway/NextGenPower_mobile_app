"""
Arduino Servo Controller
Controls the MG995 servo motor via serial communication with Arduino
"""

import serial
import time
import logging
from typing import Optional

logger = logging.getLogger(__name__)


class ServoController:
    """Controls servo motor connected to Arduino via serial communication"""
    
    def __init__(self, port: str, baudrate: int = 9600, timeout: float = 5, demo_mode: bool = False):
        """
        Initialize Servo Controller
        
        Args:
            port: Serial port (e.g., '/dev/cu.usbserial-10' on macOS)
            baudrate: Serial communication speed
            timeout: Serial read/write timeout in seconds
            demo_mode: If True, simulate Arduino responses for testing without firmware
        """
        self.port = port
        self.baudrate = baudrate
        self.timeout = timeout
        self.serial = None
        self.current_angle = 90  # Start at center
        self.is_connected = False
        self.demo_mode = demo_mode
    
    def connect(self) -> bool:
        """
        Connect to Arduino
        
        Returns:
            True if connection successful, False otherwise
        """
        if self.demo_mode:
            logger.info("DEMO MODE: Using simulated Arduino responses")
            self.is_connected = True
            logger.info(f"Connected to Arduino on {self.port} (SIMULATED)")
            return True
        
        try:
            self.serial = serial.Serial(
                port=self.port,
                baudrate=self.baudrate,
                timeout=self.timeout
            )
            # Wait longer for Arduino to reset and initialize
            time.sleep(2.5)
            
            # Clear any leftover data in buffer
            self.serial.reset_input_buffer()
            self.serial.reset_output_buffer()
            time.sleep(0.5)
            
            # Read initialization message if available
            if self.serial.in_waiting:
                response = self.serial.readline().decode('utf-8').strip()
                logger.info(f"Arduino response: {response}")
            
            self.is_connected = True
            logger.info(f"Connected to Arduino on {self.port}")
            return True
            
        except serial.SerialException as e:
            logger.error(f"Failed to connect to Arduino: {e}")
            self.is_connected = False
            return False
    
    def disconnect(self) -> None:
        """Disconnect from Arduino"""
        if self.serial and self.serial.is_open:
            self.serial.close()
            self.is_connected = False
            logger.info("Disconnected from Arduino")
    
    def set_angle(self, angle: int) -> bool:
        """
        Set servo angle
        
        Args:
            angle: Angle in degrees (0-180)
            
        Returns:
            True if successful, False otherwise
        """
        if not self.is_connected:
            logger.error("Arduino not connected")
            return False
        
        if angle < 0 or angle > 180:
            logger.error(f"Invalid angle: {angle}. Must be 0-180")
            return False
        
        try:
            if self.demo_mode:
                # Simulate servo movement
                self.current_angle = angle
                logger.info(f"DEMO MODE: Servo set to {angle}°")
                return True
            
            # Clear buffers before sending
            self.serial.reset_input_buffer()
            self.serial.reset_output_buffer()
            time.sleep(0.1)
            
            command = f"SET_ANGLE:{angle}\n"
            self.serial.write(command.encode('utf-8'))
            self.serial.flush()
            time.sleep(0.2)
            
            # Read response with timeout
            response = ""
            start_time = time.time()
            while time.time() - start_time < 1:
                if self.serial.in_waiting:
                    byte = self.serial.read(1)
                    response += byte.decode('utf-8', errors='ignore')
                    if '\n' in response:
                        break
                time.sleep(0.05)
            
            response = response.strip()
            
            if response.startswith("ANGLE_SET:"):
                confirmed_angle = int(response.split(':')[1])
                self.current_angle = confirmed_angle
                logger.info(f"Servo set to {confirmed_angle}°")
                return True
            elif response.startswith("ERROR:"):
                logger.error(f"Arduino error: {response}")
                return False
            elif response:
                # Got some response, assume success
                logger.info(f"Servo moved to {angle}°")
                self.current_angle = angle
                return True
            else:
                logger.warning(f"No response to SET_ANGLE:{angle}")
                # Still try to continue - Arduino might be working
                self.current_angle = angle
                return True
                
        except Exception as e:
            logger.error(f"Error setting angle: {e}")
            return False
    
    def convert_wind_direction_to_angle(self, wind_direction: float) -> int:
        """
        Convert wind direction (0-360°) to servo angle (0-180°)
        
        Wind direction convention:
        - 0° = North
        - 90° = East
        - 180° = South
        - 270° = West
        
        Servo mapping (assuming servo range 0-180):
        - 0-180° wind direction maps directly to 0-180° servo
        - Values above 180° wrap around (181° → 179°, etc.)
        
        Args:
            wind_direction: Wind direction in degrees (0-360)
            
        Returns:
            Servo angle (0-180)
        """
        # Normalize wind direction to 0-360
        wind_direction = wind_direction % 360
        
        # Map wind direction to servo angle
        # For a full 360° coverage with 180° servo, we need to wrap values
        if wind_direction <= 180:
            servo_angle = int(wind_direction)
        else:
            # Values above 180° map back (181° → 179°, etc.)
            servo_angle = int(360 - wind_direction)
        
        return servo_angle
    
    def get_current_angle(self) -> Optional[int]:
        """
        Get current servo angle
        
        Returns:
            Current angle (0-180) or None if error
        """
        if not self.is_connected:
            logger.error("Arduino not connected")
            return None
        
        try:
            if self.demo_mode:
                logger.info(f"DEMO MODE: Current angle is {self.current_angle}°")
                return self.current_angle
            
            # Clear buffers
            self.serial.reset_input_buffer()
            self.serial.reset_output_buffer()
            time.sleep(0.1)
            
            self.serial.write(b"GET_ANGLE\n")
            self.serial.flush()
            time.sleep(0.2)
            
            # Read response
            response = ""
            start_time = time.time()
            while time.time() - start_time < 1:
                if self.serial.in_waiting:
                    byte = self.serial.read(1)
                    response += byte.decode('utf-8', errors='ignore')
                    if '\n' in response:
                        break
                time.sleep(0.05)
            
            response = response.strip()
            
            if response.startswith("CURRENT_ANGLE:"):
                angle = int(response.split(':')[1])
                self.current_angle = angle
                return angle
            elif response:
                logger.warning(f"Unexpected response: {response}")
                return self.current_angle
            else:
                return self.current_angle
                
        except Exception as e:
            logger.error(f"Error getting angle: {e}")
            return self.current_angle
    
    def test_connection(self) -> bool:
        """
        Test Arduino connection
        
        Returns:
            True if Arduino port is open, False otherwise
        """
        if not self.is_connected:
            logger.error("Arduino not connected")
            return False
        
        try:
            if self.demo_mode:
                logger.info("DEMO MODE: Test successful (simulated)")
                return True
            
            # Check if serial port is still open
            if not self.serial or not self.serial.is_open:
                logger.warning("Serial port is not open")
                return False
            
            logger.info("Arduino connection verified (port is open and ready)")
            return True
                
        except Exception as e:
            logger.error(f"Error testing connection: {e}")
            return False
                
        except Exception as e:
            logger.error(f"Error testing connection: {e}")
            return False
