# Backend System - Complete Implementation Summary

## ✅ What Has Been Created

### 1. Flask Server (ML Inference Server)
**Location:** `flask_server/`

**Files Created:**
- `app.py` - Flask application with ML model endpoints
- `requirements.txt` - Python dependencies
- `.env.example` - Environment configuration template

**Features:**
- Loads and manages PyTorch VAE and Classifier models
- Handles preprocessing with StandardScaler
- Provides endpoints for single and batch predictions
- Returns predictions with probabilities and reconstruction errors
- Automatic GPU/CPU detection
- Health check and model info endpoints

**Endpoints:**
- `GET /health` - Server health check
- `POST /predict` - Single prediction
- `POST /predict/batch` - Batch predictions
- `GET /model/info` - Model information

### 2. Express.js Server (API Gateway)
**Location:** `express_server/`

**Files Created:**
- `server.js` - Express API server with full middleware stack
- `package.json` - Node.js dependencies
- `.env.example` - Environment configuration template

**Features:**
- RESTful API with comprehensive validation
- Rate limiting (100 requests per 15 minutes)
- Security headers (Helmet.js)
- CORS support
- Request logging (Morgan)
- Error handling and formatting
- Communicates with Flask via axios
- Detailed API documentation endpoint

**Endpoints:**
- `GET /` - API overview
- `GET /api/health` - Health check (both servers)
- `GET /api/model/info` - Model information
- `GET /api/docs` - Full API documentation
- `POST /api/predict` - Single prediction (validated)
- `POST /api/predict/batch` - Batch predictions (validated)

### 3. Utility Scripts

**`generate_scaler.py`**
- Generates the required `scaler.pkl` file from training data
- Must be run before starting Flask server

**`test_api.py`**
- Comprehensive API testing script
- Tests all endpoints with sample data
- Validates error handling

**`setup.bat`**
- Automated setup script for Windows
- Creates .env files
- Installs all dependencies

**`start_servers.bat`**
- Starts both Flask and Express servers in separate terminals
- Convenient for development

### 4. Documentation

**`BACKEND_README.md`**
- Complete system documentation
- Installation and setup instructions
- API endpoint details with examples
- Input/output formats
- Troubleshooting guide
- Security features
- Production deployment recommendations

**`REQUIREMENTS.md`**
- Detailed dependency list
- Installation commands
- Version requirements
- Troubleshooting for installation issues
- Development and production setup

**`QUICKSTART.md`**
- Quick start guide for immediate setup
- Step-by-step instructions
- Common issues and fixes
- Example requests and responses

**`ARCHITECTURE.md`**
- System architecture overview
- Data flow diagrams
- File structure
- Technology stack details
- Model architecture
- Security features
- Performance considerations
- Scaling recommendations

**`.gitignore`**
- Configured for Python and Node.js projects
- Excludes node_modules, __pycache__, .env files, etc.

## 📋 Requirements to Install

### Python Dependencies (Flask Server)
```
torch>=1.10.0
numpy>=1.21.0
pandas>=1.3.0
scikit-learn>=0.24.0
Flask>=2.0.0
flask-cors>=3.0.10
pickle5>=0.0.11
```

**Install Command:**
```cmd
cd flask_server
pip install -r requirements.txt
```

### Node.js Dependencies (Express Server)
```
express: ^4.18.2
axios: ^1.6.0
cors: ^2.8.5
helmet: ^7.1.0
morgan: ^1.10.0
express-rate-limit: ^7.1.5
dotenv: ^16.3.1
```

**Install Command:**
```cmd
cd express_server
npm install
```

## 🚀 How to Start (Quick)

### Option 1: Automated Setup
```cmd
REM 1. Run setup
setup.bat

REM 2. Generate scaler (first time only)
python generate_scaler.py

REM 3. Start both servers
start_servers.bat
```

### Option 2: Manual Setup
```cmd
REM Terminal 1 - Install dependencies
cd flask_server
pip install -r requirements.txt
cd ..

cd express_server
npm install
cd ..

REM Generate scaler (first time only)
python generate_scaler.py

REM Terminal 2 - Start Flask
cd flask_server
python app.py

REM Terminal 3 - Start Express
cd express_server
npm start
```

## 🔍 Model Input/Output

### Input Format (8 Features)
```json
{
  "air_temperature": 300.0,        // Kelvin
  "process_temperature": 310.0,     // Kelvin
  "rotational_speed": 1500,         // RPM
  "torque": 40.0,                   // Nm
  "tool_wear": 100,                 // minutes
  "type_H": 0,                      // 0 or 1
  "type_L": 1,                      // 0 or 1 (exactly one type = 1)
  "type_M": 0                       // 0 or 1
}
```

### Output Format
```json
{
  "success": true,
  "data": {
    "predicted_failure_type": "No Failure",
    "confidence": "95.50%",
    "probability": 0.955,
    "reconstruction_error": 0.02,
    "all_probabilities": {
      "No Failure": 0.955,
      "Heat Dissipation Failure": 0.020,
      "Power Failure": 0.015,
      "Overstrain Failure": 0.005,
      "Tool Wear Failure": 0.003,
      "Random Failures": 0.002
    },
    "is_anomaly": false,
    "device_used": "cuda"
  },
  "input": { ... },
  "timestamp": "2025-11-30T10:30:00.000Z"
}
```

## 🏗️ System Architecture

```
Client → Express.js (Port 3002) → Flask (Port 5002) → PyTorch Model
           ↓                           ↓
    Validation                   Preprocessing
    Rate Limiting                VAE + Classifier
    Error Formatting             Predictions
```

**Express Server:**
- Validates input
- Manages rate limiting
- Formats responses
- Handles errors

**Flask Server:**
- Loads ML models
- Preprocesses data (StandardScaler)
- Runs inference (VAE + Classifier)
- Returns predictions with confidence scores

## ✅ Pre-Deployment Checklist

Before starting the servers:

- [ ] Python 3.8+ installed
- [ ] Node.js 14+ installed
- [ ] Python dependencies installed (`pip install -r requirements.txt`)
- [ ] Node.js dependencies installed (`npm install`)
- [ ] `scaler.pkl` generated (`python generate_scaler.py`)
- [ ] All model files exist in `Models/`:
  - [ ] `vae_model.pth`
  - [ ] `classifier_model.pth`
  - [ ] `scaler.pkl`
  - [ ] `label_encoder.pkl`
- [ ] `.env` files configured in both server directories
- [ ] Ports 3002 and 5002 available

## 🧪 Testing

```cmd
REM Test all endpoints
python test_api.py

REM Or manually test
curl http://localhost:3002/api/health
curl http://localhost:3002/api/docs
```

## 📚 Documentation Files

1. **QUICKSTART.md** - Start here for quick setup
2. **BACKEND_README.md** - Complete documentation
3. **REQUIREMENTS.md** - Dependency details
4. **ARCHITECTURE.md** - System architecture and design

## 🔧 Key Features

### Security
- Rate limiting (100 requests/15 min)
- Helmet.js security headers
- CORS configured
- Input validation
- Safe error messages

### Performance
- GPU support (automatic fallback to CPU)
- Batch prediction support
- Models loaded once on startup
- Persistent HTTP connections

### Developer Experience
- Comprehensive API documentation at `/api/docs`
- Detailed error messages
- Request logging
- Auto-reload in dev mode (`npm run dev`)

### Production Ready
- Environment configuration
- Error handling
- Health checks
- Logging
- Rate limiting
- Security headers

## 📞 API Usage Example

```javascript
// JavaScript/Node.js
const axios = require('axios');

const data = {
  air_temperature: 300.0,
  process_temperature: 310.0,
  rotational_speed: 1500,
  torque: 40.0,
  tool_wear: 100,
  type_H: 0,
  type_L: 1,
  type_M: 0
};

axios.post('http://localhost:3002/api/predict', data)
  .then(response => {
    console.log('Prediction:', response.data.data.predicted_failure_type);
    console.log('Confidence:', response.data.data.confidence);
  })
  .catch(error => {
    console.error('Error:', error.response?.data || error.message);
  });
```

```python
# Python
import requests

data = {
    "air_temperature": 300.0,
    "process_temperature": 310.0,
    "rotational_speed": 1500,
    "torque": 40.0,
    "tool_wear": 100,
    "type_H": 0,
    "type_L": 1,
    "type_M": 0
}

response = requests.post('http://localhost:3002/api/predict', json=data)
result = response.json()

print(f"Prediction: {result['data']['predicted_failure_type']}")
print(f"Confidence: {result['data']['confidence']}")
```

## 🚨 Common Issues

**Issue:** "scaler.pkl not found"
**Solution:** Run `python generate_scaler.py`

**Issue:** "Cannot connect to Flask"
**Solution:** Ensure Flask is running on port 5002

**Issue:** Port already in use
**Solution:** Change PORT in .env or stop conflicting process

**Issue:** Module not found
**Solution:** Install dependencies: `pip install -r requirements.txt` or `npm install`

## 📈 Next Steps

1. **Start the servers** using the quick start guide
2. **Test the API** with the provided test script
3. **Integrate** with your frontend application
4. **Deploy** to production (see BACKEND_README.md)
5. **Monitor** logs and performance
6. **Scale** as needed (see ARCHITECTURE.md)

## 🎯 Success Indicators

When everything is working correctly:
- ✅ Flask shows: "Model loaded successfully!"
- ✅ Express shows: "Express server running on port 3002"
- ✅ Health check returns 200: http://localhost:3002/api/health
- ✅ Docs accessible: http://localhost:3002/api/docs
- ✅ Predictions return valid results

## 📝 Files Created Summary

```
├── flask_server/
│   ├── app.py (Flask ML server)
│   ├── requirements.txt (Python deps)
│   └── .env.example (Config template)
│
├── express_server/
│   ├── server.js (Express API)
│   ├── package.json (Node deps)
│   └── .env.example (Config template)
│
├── generate_scaler.py (Scaler generation)
├── test_api.py (API tests)
├── setup.bat (Automated setup)
├── start_servers.bat (Server launcher)
│
├── BACKEND_README.md (Main docs)
├── REQUIREMENTS.md (Dependencies)
├── QUICKSTART.md (Quick start)
├── ARCHITECTURE.md (Architecture)
├── SUMMARY.md (This file)
└── .gitignore (Git config)
```

## 🎉 You're Ready!

The complete backend system is now set up. Follow the Quick Start guide to get started!
