# System Architecture Overview

## System Flow Diagram

```
┌─────────────────┐
│   Client App    │
│  (Web/Mobile)   │
└────────┬────────┘
         │ HTTP Request
         ▼
┌─────────────────────────────────────────────────────────┐
│              Express.js Server (Port 3002)               │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Middleware Stack                                 │  │
│  │  • CORS (Cross-Origin)                           │  │
│  │  • Helmet (Security Headers)                     │  │
│  │  • Rate Limiting (100 req/15min)                 │  │
│  │  • JSON Body Parser                              │  │
│  │  • Morgan (Request Logging)                      │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  API Routes                                       │  │
│  │  • GET  /api/health                              │  │
│  │  • GET  /api/model/info                          │  │
│  │  • POST /api/predict                             │  │
│  │  • POST /api/predict/batch                       │  │
│  │  • GET  /api/docs                                │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Input Validation                                 │  │
│  │  • Check required fields (8 features)            │  │
│  │  • Validate data types                           │  │
│  │  • Ensure exactly one type selected              │  │
│  └──────────────────────────────────────────────────┘  │
└──────────────────────┬──────────────────────────────────┘
                       │ HTTP POST (axios)
                       ▼
┌─────────────────────────────────────────────────────────┐
│               Flask Server (Port 5002)                   │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Model Loading (On Startup)                       │  │
│  │  • Load VAE Model (vae_model.pth)                │  │
│  │  • Load Classifier (classifier_model.pth)        │  │
│  │  • Load StandardScaler (scaler.pkl)              │  │
│  │  • Load LabelEncoder (label_encoder.pkl)         │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Preprocessing Pipeline                           │  │
│  │  • StandardScaler Transform                       │  │
│  │  • Convert to PyTorch Tensor                     │  │
│  │  • Move to Device (GPU/CPU)                      │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Neural Network Inference                         │  │
│  │                                                   │  │
│  │  ┌──────────────────────────────────────────┐   │  │
│  │  │ VAE (Variational Autoencoder)             │   │  │
│  │  │ • Encoder: 8 → 128 → 128                 │   │  │
│  │  │ • Latent Space: 64 dimensions            │   │  │
│  │  │ • Decoder: 64 → 128 → 128 → 8            │   │  │
│  │  │ • Outputs: Reconstruction, mu, log_var   │   │  │
│  │  └──────────────────────────────────────────┘   │  │
│  │                    │                              │  │
│  │                    ▼                              │  │
│  │  ┌──────────────────────────────────────────┐   │  │
│  │  │ Classifier (VAEClassifier)                │   │  │
│  │  │ • Uses VAE's latent representation        │   │  │
│  │  │ • 64 → 64 → 6 classes                    │   │  │
│  │  │ • Softmax output                          │   │  │
│  │  └──────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Post-processing                                  │  │
│  │  • Calculate probabilities (softmax)             │  │
│  │  • Decode class labels                           │  │
│  │  • Compute reconstruction error (MSE)            │  │
│  │  • Generate all class probabilities              │  │
│  └──────────────────────────────────────────────────┘  │
└──────────────────────┬──────────────────────────────────┘
                       │ JSON Response
                       ▼
┌─────────────────────────────────────────────────────────┐
│              Express.js Server (Port 3002)               │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Response Formatting                              │  │
│  │  • Add confidence percentage                      │  │
│  │  • Flag anomalies (recon_error > 0.1)           │  │
│  │  • Add timestamp                                  │  │
│  │  • Format success response                        │  │
│  └──────────────────────────────────────────────────┘  │
└──────────────────────┬──────────────────────────────────┘
                       │ HTTP Response
                       ▼
┌─────────────────┐
│   Client App    │
│  (Web/Mobile)   │
└─────────────────┘
```

## Data Flow

### Input Data (8 Features)
```
1. air_temperature       (Kelvin)
2. process_temperature   (Kelvin)
3. rotational_speed      (RPM)
4. torque               (Nm)
5. tool_wear            (minutes)
6. type_H               (0 or 1)
7. type_L               (0 or 1)
8. type_M               (0 or 1)
```

### Processing Steps
```
1. Input → Express Validation → Flask Server
2. Flask: StandardScaler Transform
3. Flask: VAE Encoding (8 → 128 → 64)
4. Flask: Classification (64 → 64 → 6)
5. Flask: VAE Reconstruction for Anomaly Score
6. Flask: Softmax & Label Decoding
7. Response → Express Formatting → Client
```

### Output Data
```json
{
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
  "is_anomaly": false
}
```

## File Structure

```
TSYP12-IAS-challenge-IEEE-SUPCOM-SB/
├── flask_server/
│   ├── app.py                  # Flask application with ML model
│   ├── requirements.txt        # Python dependencies
│   └── .env.example           # Environment template
│
├── express_server/
│   ├── server.js              # Express API server
│   ├── package.json           # Node.js dependencies
│   └── .env.example           # Environment template
│
├── Models/
│   ├── vae_model.pth          # Trained VAE weights
│   ├── classifier_model.pth   # Trained classifier weights
│   ├── scaler.pkl             # Fitted StandardScaler
│   └── label_encoder.pkl      # Fitted LabelEncoder
│
├── Dataset/
│   └── predictive_maintenance.csv
│
├── generate_scaler.py         # Script to create scaler.pkl
├── test_api.py                # API testing script
├── setup.bat                  # Automated setup
├── start_servers.bat          # Start both servers
│
├── BACKEND_README.md          # Main documentation
├── REQUIREMENTS.md            # Dependency details
├── QUICKSTART.md              # Quick start guide
└── ARCHITECTURE.md            # This file
```

## Technology Stack

### Backend API (Express.js)
- **express** - Web framework
- **axios** - HTTP client for Flask communication
- **cors** - Cross-origin resource sharing
- **helmet** - Security middleware
- **morgan** - HTTP logging
- **express-rate-limit** - API rate limiting
- **dotenv** - Environment configuration

### ML Server (Flask)
- **torch** - PyTorch deep learning framework
- **numpy** - Numerical computing
- **pandas** - Data manipulation
- **scikit-learn** - Preprocessing tools
- **flask** - Python web framework
- **flask-cors** - CORS for Flask

## Model Architecture Details

### VAE (Variational Autoencoder)
- **Purpose**: Feature learning and anomaly detection
- **Input**: 8 features (sensor data)
- **Encoder**: 8 → 128 → 128 → 64 (latent)
- **Decoder**: 64 → 128 → 128 → 8 (reconstruction)
- **Training**: Reconstruction loss + KL divergence
- **Output**: Reconstructed features, latent representation

### Classifier
- **Purpose**: Failure type prediction
- **Input**: 64-dimensional latent representation from VAE
- **Architecture**: 64 → 64 → 6 (failure classes)
- **Output**: Class probabilities (softmax)
- **Classes**: 6 failure types

## Security Features

1. **Rate Limiting**: 100 requests per 15 minutes per IP
2. **Helmet.js**: Security headers (XSS, CSRF protection)
3. **CORS**: Configured cross-origin access
4. **Input Validation**: Strict validation of all inputs
5. **Error Handling**: Safe error messages (no stack traces to client)

## Performance Considerations

- **GPU Acceleration**: Automatic CUDA detection and fallback to CPU
- **Model Loading**: Models loaded once on server startup
- **Batch Processing**: Support for batch predictions
- **Connection Pooling**: Axios persistent connections to Flask
- **Caching**: StandardScaler and LabelEncoder loaded once

## Scaling Recommendations

### Horizontal Scaling
- Deploy multiple Flask instances behind load balancer
- Use Redis for session management if needed
- Consider containerization (Docker)

### Vertical Scaling
- GPU for faster inference
- Increase worker threads (Flask: gunicorn -w N)
- Optimize batch size for throughput

### Production Deployment
- Use gunicorn/uWSGI for Flask
- Use PM2 for Express.js
- Set up reverse proxy (nginx)
- Enable HTTPS
- Implement monitoring and logging
- Set up health checks and auto-restart

## API Response Times (Typical)

- **Health Check**: <50ms
- **Model Info**: <100ms
- **Single Prediction**: 50-200ms (GPU) / 100-500ms (CPU)
- **Batch Prediction**: Depends on batch size, ~100ms per sample

## Error Codes

- **200 OK**: Success
- **400 Bad Request**: Invalid input
- **429 Too Many Requests**: Rate limit exceeded
- **500 Internal Server Error**: Model/server error
- **503 Service Unavailable**: Flask server down

## Maintenance

### Regular Tasks
- Monitor logs for errors
- Check disk space for logs
- Update dependencies periodically
- Retrain models with new data

### Backup
- Model files (Models/*.pth, Models/*.pkl)
- Environment configurations
- Dataset backups

## Support & Troubleshooting

See BACKEND_README.md for detailed troubleshooting guide.
```
