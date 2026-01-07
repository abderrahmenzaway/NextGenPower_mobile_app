# Predictive Maintenance Backend System

This backend system provides a complete API infrastructure for running predictive maintenance predictions using a VAE-based machine learning model.

## Architecture

The system consists of two servers:

1. **Flask Server** (Port 5002): Handles ML model inference
   - Loads and manages PyTorch VAE and Classifier models
   - Processes predictions with preprocessing (StandardScaler)
   - Returns failure predictions with probabilities and reconstruction errors

2. **Express.js Server** (Port 3002): Main API gateway
   - Validates and formats client requests
   - Communicates with Flask server
   - Provides rate limiting, security headers, and error handling
   - Returns formatted responses to clients

## Model Input/Output

### Input Format
The model expects 8 features representing machine sensor data:

```json
{
  "air_temperature": 300.0,          // Air temperature in Kelvin
  "process_temperature": 310.0,       // Process temperature in Kelvin
  "rotational_speed": 1500,           // RPM
  "torque": 40.0,                     // Nm
  "tool_wear": 100,                   // Minutes
  "type_H": 0,                        // High quality (0 or 1)
  "type_L": 1,                        // Low quality (0 or 1)
  "type_M": 0                         // Medium quality (0 or 1)
}
```

**Note:** Exactly one type (H, L, or M) must be set to 1.

### Output Format
The API returns:

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

## Installation & Setup

### Prerequisites
- Python 3.8+
- Node.js 14+
- CUDA-compatible GPU (optional, CPU works too)

### Step 1: Install Python Dependencies

```cmd
cd flask_server
pip install -r requirements.txt
```

**Flask Server Requirements:**
- torch>=1.10.0
- numpy>=1.21.0
- pandas>=1.3.0
- scikit-learn>=0.24.0
- Flask>=2.0.0
- flask-cors>=3.0.10
- pickle5>=0.0.11

### Step 2: Install Node.js Dependencies

```cmd
cd ..\express_server
npm install
```

**Express Server Requirements:**
- express: ^4.18.2
- axios: ^1.6.0
- cors: ^2.8.5
- helmet: ^7.1.0
- morgan: ^1.10.0
- express-rate-limit: ^7.1.5
- dotenv: ^16.3.1

### Step 3: Ensure Model Files Exist

Make sure the following files are in the `Models/` directory:
- `vae_model.pth` - Trained VAE model
- `classifier_model.pth` - Trained classifier model
- `scaler.pkl` - Fitted StandardScaler
- `label_encoder.pkl` - Fitted LabelEncoder

### Step 4: Configure Environment Variables

**Flask Server:**
```cmd
cd flask_server
copy .env.example .env
```

**Express Server:**
```cmd
cd express_server
copy .env.example .env
```

Edit `.env` files as needed.

## Running the Servers

### Start Flask Server (Terminal 1)

```cmd
cd flask_server
python app.py
```

The Flask server will start on http://localhost:5002

### Start Express Server (Terminal 2)

```cmd
cd express_server
npm start
```

The Express server will start on http://localhost:3002

For development with auto-reload:
```cmd
npm run dev
```

## API Endpoints

### 1. Health Check
```http
GET http://localhost:3002/api/health
```

Checks if both servers are running properly.

### 2. Model Information
```http
GET http://localhost:3002/api/model/info
```

Returns model details, feature names, and available failure classes.

### 3. Single Prediction
```http
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

### 4. Batch Prediction
```http
POST http://localhost:3002/api/predict/batch
Content-Type: application/json

{
  "samples": [
    {
      "air_temperature": 300.0,
      "process_temperature": 310.0,
      "rotational_speed": 1500,
      "torque": 40.0,
      "tool_wear": 100,
      "type_H": 0,
      "type_L": 1,
      "type_M": 0
    },
    {
      "air_temperature": 305.0,
      "process_temperature": 315.0,
      "rotational_speed": 1600,
      "torque": 45.0,
      "tool_wear": 120,
      "type_H": 1,
      "type_L": 0,
      "type_M": 0
    }
  ]
}
```

### 5. API Documentation
```http
GET http://localhost:3002/api/docs
```

Returns complete API documentation in JSON format.

## Testing the API

### Using curl:

```cmd
curl -X POST http://localhost:3002/api/predict ^
  -H "Content-Type: application/json" ^
  -d "{\"air_temperature\":300.0,\"process_temperature\":310.0,\"rotational_speed\":1500,\"torque\":40.0,\"tool_wear\":100,\"type_H\":0,\"type_L\":1,\"type_M\":0}"
```

### Using PowerShell:

```powershell
$body = @{
    air_temperature = 300.0
    process_temperature = 310.0
    rotational_speed = 1500
    torque = 40.0
    tool_wear = 100
    type_H = 0
    type_L = 1
    type_M = 0
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:3002/api/predict" -Method POST -Body $body -ContentType "application/json"
```

## Error Handling

The API provides detailed error messages:

- **400 Bad Request**: Missing or invalid input data
- **500 Internal Server Error**: Model prediction failure
- **503 Service Unavailable**: Flask server not reachable
- **429 Too Many Requests**: Rate limit exceeded (100 requests per 15 minutes)

## Security Features

- **Helmet.js**: Security headers
- **CORS**: Cross-origin resource sharing enabled
- **Rate Limiting**: 100 requests per 15 minutes per IP
- **Input Validation**: Strict validation of all inputs
- **Error Handling**: Comprehensive error handling with safe error messages

## Failure Types

The model predicts 6 failure types:
1. No Failure
2. Heat Dissipation Failure
3. Power Failure
4. Overstrain Failure
5. Tool Wear Failure
6. Random Failures

## Troubleshooting

### Flask server won't start
- Ensure all model files exist in `Models/` directory
- Check Python dependencies are installed
- Verify `scaler.pkl` and `label_encoder.pkl` exist

### Express server can't connect to Flask
- Verify Flask server is running on port 5002
- Check `FLASK_URL` in Express `.env` file
- Ensure firewall allows local connections

### CUDA errors
- The model will automatically fall back to CPU if CUDA is unavailable
- Check `device_used` in response to see which device was used

### Rate limit errors
- Wait 15 minutes or adjust rate limit in `server.js`
- Rate limit applies per IP address

## Development

### Adding New Features
1. Modify `flask_server/app.py` for ML changes
2. Modify `express_server/server.js` for API changes
3. Update this README with new endpoints or requirements

### Running in Production
- Set `NODE_ENV=production` in Express `.env`
- Set `FLASK_ENV=production` and `FLASK_DEBUG=0` in Flask `.env`
- Use a process manager like PM2 for Express
- Use gunicorn or uWSGI for Flask
- Set up reverse proxy (nginx/Apache)
- Enable HTTPS

## License

See LICENSE file for details.

## Support

For issues or questions, please contact the development team.
