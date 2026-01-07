# Wind Turbine Control

A Python + Arduino project that aligns a servo-based turbine to the current wind direction from OpenWeather.

## What’s inside
- CLI app: `src/main.py` (prompts for City, Latitude, Longitude and runs updates)
- Web app: `web/app.py` (simple UI to connect, set angle, fetch weather, update)
- Arduino firmware: `arduino/wind_turbine_control.ino`
- Config: `config/config.json`

## Requirements
- Python 3.8+
- Arduino (Uno/Nano/Mega)
- MG995 servo (use external 5–6V supply; common GND with Arduino)
- Dependencies: `pip install -r requirements.txt`

### Install dependencies
Use your Python environment and install required packages:
```zsh
pip install -r requirements.txt
```
If you use conda or a venv, activate it before installing.

## Configure
Edit `config/config.json`:
- openweather.api_key: your OpenWeather API key
- openweather.city/latitude/longitude: location
- arduino.port: serial device (macOS examples: `/dev/cu.usbmodem****`, `/dev/cu.usbserial****`)
- arduino.demo_mode: true to test without hardware

## Run (choose one)
### CLI
```zsh
python src/main.py
```
- Prompts for City, Latitude, Longitude and saves to config.

### Web
```zsh
cd web
python app.py
```
Open http://127.0.0.1:5000

## Common issues
- Port busy: Close Arduino IDE Serial Monitor and stop the other app (web vs CLI).
- Wrong port: Run `ls /dev/cu.usbmodem* /dev/cu.usbserial*` and set `arduino.port`.
- Servo power: Don’t power MG995 from Arduino 5V; use external PSU and tie grounds.

## Project structure
```
arduino/                 # Firmware
config/config.json       # Settings
src/                     # CLI app
web/app.py               # Flask web server
web/templates/index.html # Web UI
web/static/style.css     # Web UI styles
requirements.txt         # Dependencies
README.md                # This file
```

