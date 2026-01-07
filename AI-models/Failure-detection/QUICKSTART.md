# Quick Start Guide

## Prerequisites Check
- [ ] Python 3.8+ installed? Check: `python --version`
- [ ] Node.js 14+ installed? Check: `node --version`
- [ ] npm installed? Check: `npm --version`

## Step 1: Install Dependencies

### Automatic Setup (Recommended)
```cmd
setup.bat
```

### Manual Setup
```cmd
REM Install Python dependencies
cd flask_server
pip install -r requirements.txt
cd ..

REM Install Node.js dependencies
cd express_server
npm install
cd ..
```

## Step 2: Generate Scaler (IMPORTANT - First Time Only)

**If using virtual environment (venv):**
```cmd
cd flask_server
venv\Scripts\activate
cd ..
python generate_scaler.py
deactivate
```

**If not using venv:**
```cmd
python generate_scaler.py
```

This creates the `scaler.pkl` file needed by the Flask server.

## Step 3: Start Servers

### Option A: Start Both Servers Automatically
```cmd
start_servers.bat
```

### Option B: Start Manually (Two Terminals)

**Terminal 1 - Flask Server:**
```cmd
cd flask_server
venv\Scripts\activate
python app.py
```

**Terminal 2 - Express Server:**
```cmd
cd express_server
npm start
```

## Step 4: Test the API

### Browser Test
Open in browser: http://localhost:3002/api/docs

### Command Line Test
```cmd
python test_api.py
```

### Manual API Test
```cmd
curl -X POST http://localhost:3002/api/predict ^
  -H "Content-Type: application/json" ^
  -d "{\"air_temperature\":300.0,\"process_temperature\":310.0,\"rotational_speed\":1500,\"torque\":40.0,\"tool_wear\":100,\"type_H\":0,\"type_L\":1,\"type_M\":0}"
```

## Success Indicators

✓ Flask server shows: "Model loaded successfully!"
✓ Express server shows: "Express server running on port 3002"
✓ Health check returns status 200: http://localhost:3002/api/health

## Common Issues

**Issue:** "scaler.pkl not found"
**Fix:** Activate venv first: `cd flask_server && venv\Scripts\activate && cd .. && python generate_scaler.py`

**Issue:** "ModuleNotFoundError" when running generate_scaler.py
**Fix:** Activate the virtual environment before running the script

**Issue:** "Port already in use"
**Fix:** Change PORT in .env or stop the conflicting process

**Issue:** "Cannot connect to Flask server"
**Fix:** Ensure Flask is running on port 5002

## API Endpoints

- `GET  /api/health` - Health check
- `GET  /api/model/info` - Model information
- `GET  /api/docs` - Full API documentation
- `POST /api/predict` - Single prediction
- `POST /api/predict/batch` - Batch predictions

## Example Request

```json
POST http://localhost:3002/api/predict
Content-Type: application/json

{
  "air_temperature": 300.0,
  "process_temperature": 310.0,
  "rotational_speed": 1500,
  "torque": 40.0,
  "tool_wear": 100,
  "type_H": 0,
  "type_L": 1,
  "type_M": 0
}
```

## Example Response

```json
{
  "success": true,
  "data": {
    "predicted_failure_type": "No Failure",
    "confidence": "95.50%",
    "probability": 0.955,
    "reconstruction_error": 0.02,
    "is_anomaly": false
  }
}
```

## Next Steps

1. Read `BACKEND_README.md` for detailed documentation
2. See `REQUIREMENTS.md` for dependency details
3. Check `test_api.py` for testing examples

## Need Help?

- Check logs in the terminal windows
- Verify all model files exist in `Models/` directory
- Ensure ports 3002 and 5002 are available
- Review error messages for specific issues
