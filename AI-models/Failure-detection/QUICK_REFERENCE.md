# 🚀 Quick Reference Card

## Installation (One-Time Setup)

```cmd
setup.bat
python generate_scaler.py
```

## Start Servers

```cmd
start_servers.bat
```

OR manually:
```cmd
REM Terminal 1
cd flask_server && python app.py

REM Terminal 2
cd express_server && npm start
```

## Test API

```cmd
python test_api.py
```

OR:
```cmd
curl http://localhost:3002/api/health
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check |
| GET | `/api/model/info` | Model info |
| GET | `/api/docs` | Full documentation |
| POST | `/api/predict` | Single prediction |
| POST | `/api/predict/batch` | Batch predictions |

## Example Request

```bash
curl -X POST http://localhost:3002/api/predict \
  -H "Content-Type: application/json" \
  -d '{"air_temperature":300.0,"process_temperature":310.0,"rotational_speed":1500,"torque":40.0,"tool_wear":100,"type_H":0,"type_L":1,"type_M":0}'
```

## Input Fields (All Required)

- `air_temperature` (number, Kelvin)
- `process_temperature` (number, Kelvin)  
- `rotational_speed` (number, RPM)
- `torque` (number, Nm)
- `tool_wear` (number, minutes)
- `type_H` (0 or 1)
- `type_L` (0 or 1)
- `type_M` (0 or 1)

**Note:** Exactly one type must be 1

## Output Fields

- `predicted_failure_type` - The predicted failure class
- `confidence` - Confidence percentage
- `probability` - Raw probability (0-1)
- `reconstruction_error` - Anomaly score
- `all_probabilities` - Probabilities for all classes
- `is_anomaly` - Boolean flag (if recon_error > 0.1)

## Ports

- **Flask:** 5002
- **Express:** 3002

## Required Files in Models/

- ✓ vae_model.pth
- ✓ classifier_model.pth
- ✓ scaler.pkl (generated)
- ✓ label_encoder.pkl

## Common Commands

```cmd
REM Full setup
setup.bat

REM Generate scaler
python generate_scaler.py

REM Start both servers
start_servers.bat

REM Test API
python test_api.py

REM Install Python deps
cd flask_server && pip install -r requirements.txt

REM Install Node deps
cd express_server && npm install

REM Dev mode (Express)
cd express_server && npm run dev
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| scaler.pkl not found | Run `python generate_scaler.py` |
| Port in use | Change PORT in .env |
| Flask unreachable | Check Flask is on port 5002 |
| Module not found | Run `pip install -r requirements.txt` or `npm install` |

## Documentation

- **QUICKSTART.md** - Quick start guide
- **BACKEND_README.md** - Full documentation  
- **REQUIREMENTS.md** - Dependencies
- **ARCHITECTURE.md** - System design
- **SUMMARY.md** - Complete overview

## URLs

- Express API: http://localhost:3002
- Flask API: http://localhost:5002
- API Docs: http://localhost:3002/api/docs
- Health: http://localhost:3002/api/health

## Dependencies

**Python:** torch, numpy, pandas, scikit-learn, Flask, flask-cors, pickle5

**Node.js:** express, axios, cors, helmet, morgan, express-rate-limit, dotenv

---

💡 **Tip:** Visit http://localhost:3002/api/docs for interactive API documentation
