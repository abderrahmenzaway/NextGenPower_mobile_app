#!/usr/bin/env python3
from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
import json
from pathlib import Path
import logging
import sys

# Ensure project root is on PYTHONPATH so `src` imports work when running from /web
ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

try:
    from src.weather_client import WeatherClient
    from src.servo_controller import ServoController
except ModuleNotFoundError:
    # Fallback: ensure root path is first and retry
    ROOT = Path(__file__).resolve().parents[1]
    if str(ROOT) not in sys.path:
        sys.path.insert(0, str(ROOT))
    from src.weather_client import WeatherClient
    from src.servo_controller import ServoController

app = Flask(__name__)
app.secret_key = "wind-turbine-secret"

# Load configuration
CONFIG_PATH = ROOT / "config" / "config.json"

with open(CONFIG_PATH, "r") as f:
    CONFIG = json.load(f)

# Setup logging similar to main.py
log_file = ROOT / CONFIG["logging"]["log_file"]
log_file.parent.mkdir(parents=True, exist_ok=True)
logging.basicConfig(
    level=getattr(logging, CONFIG["logging"]["log_level"]),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_file),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("web")

# Initialize clients (lazy init for Arduino)
weather_cfg = CONFIG["openweather"]
weather_client = WeatherClient(
    api_key=weather_cfg["api_key"],
    latitude=weather_cfg["latitude"],
    longitude=weather_cfg["longitude"],
    units=weather_cfg.get("units", "metric")
)

arduino_cfg = CONFIG["arduino"]
servo = ServoController(
    port=arduino_cfg["port"],
    baudrate=arduino_cfg.get("baudrate", 9600),
    timeout=arduino_cfg.get("timeout", 5),
    demo_mode=arduino_cfg.get("demo_mode", False)
)

arduino_connected = False

@app.route("/")
def index():
    return render_template(
        "index.html",
        config=CONFIG,
        arduino_connected=arduino_connected,
    )

@app.route("/update-location", methods=["POST"]) 
def update_location():
    """Update latitude, longitude, and city in config.json and reload clients."""
    try:
        city = request.form.get("city", "").strip()
        lat = float(request.form.get("latitude", "0").strip())
        lon = float(request.form.get("longitude", "0").strip())
    except ValueError:
        flash("Latitude and Longitude must be numbers", "error")
        return redirect(url_for("index"))

    if not city:
        flash("City name is required", "error")
        return redirect(url_for("index"))

    # Update in-memory config
    CONFIG["openweather"]["city"] = city
    CONFIG["openweather"]["latitude"] = lat
    CONFIG["openweather"]["longitude"] = lon

    # Persist to file
    try:
        with open(CONFIG_PATH, "w") as f:
            json.dump(CONFIG, f, indent=2)
        flash("Location updated successfully", "success")
    except Exception as e:
        logger.exception("Failed to write config.json")
        flash("Failed to save configuration", "error")
        return redirect(url_for("index"))

    # Recreate weather client with new coords
    global weather_client
    weather_cfg = CONFIG["openweather"]
    weather_client = WeatherClient(
        api_key=weather_cfg["api_key"],
        latitude=weather_cfg["latitude"],
        longitude=weather_cfg["longitude"],
        units=weather_cfg.get("units", "metric")
    )

    return redirect(url_for("index"))

@app.route("/connect", methods=["POST"]) 
def connect_arduino():
    global arduino_connected
    if arduino_connected:
        flash("Arduino already connected", "info")
        return redirect(url_for("index"))
    ok = servo.connect()
    arduino_connected = ok
    if ok:
        # Be lenient: consider test passing if port is open
        if servo.test_connection():
            flash(f"Connected to Arduino on {servo.port}", "success")
        else:
            flash(f"Connected, but test response missing. Proceeding.", "warning")
    else:
        flash("Failed to connect to Arduino", "error")
    return redirect(url_for("index"))

@app.route("/disconnect", methods=["POST"]) 
def disconnect_arduino():
    global arduino_connected
    servo.disconnect()
    arduino_connected = False
    flash("Disconnected from Arduino", "info")
    return redirect(url_for("index"))

@app.route("/weather", methods=["GET"]) 
def get_weather():
    data = weather_client.get_full_weather()
    if data:
        return jsonify(data)
    return jsonify({"error": "Failed to fetch weather"}), 500

@app.route("/update", methods=["POST"]) 
def update_turbine():
    if not arduino_connected:
        flash("Arduino not connected", "error")
        return redirect(url_for("index"))
    wd = weather_client.get_wind_direction()
    if wd is None:
        flash("Failed to fetch wind direction", "error")
        return redirect(url_for("index"))
    angle = servo.convert_wind_direction_to_angle(wd)
    ok = servo.set_angle(angle)
    if ok:
        flash(f"Wind {wd}° → Servo {angle}°", "success")
    else:
        flash("Failed to set servo angle", "error")
    return redirect(url_for("index"))

@app.route("/set-angle", methods=["POST"]) 
def set_angle():
    if not arduino_connected:
        flash("Arduino not connected", "error")
        return redirect(url_for("index"))
    try:
        angle = int(request.form.get("angle", "0"))
    except ValueError:
        flash("Invalid angle", "error")
        return redirect(url_for("index"))
    if angle < 0 or angle > 180:
        flash("Angle must be between 0 and 180", "error")
        return redirect(url_for("index"))
    ok = servo.set_angle(angle)
    if ok:
        flash(f"Servo set to {angle}°", "success")
    else:
        flash("Failed to set angle", "error")
    return redirect(url_for("index"))

@app.route("/current-angle", methods=["GET"]) 
def current_angle():
    if not arduino_connected:
        return jsonify({"error": "Arduino not connected"}), 400
    angle = servo.get_current_angle()
    if angle is None:
        return jsonify({"error": "Failed to read angle"}), 500
    return jsonify({"angle": angle})

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)
