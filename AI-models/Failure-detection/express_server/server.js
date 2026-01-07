const express = require('express');
const axios = require('axios');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const app = express();

// Configuration
const PORT = process.env.PORT || 3002;
const FLASK_URL = process.env.FLASK_URL || 'http://localhost:5002';

// Middleware
app.use(helmet()); // Security headers
app.use(cors()); // Enable CORS
app.use(express.json()); // Parse JSON bodies
app.use(morgan('combined')); // Logging

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // Limit each IP to 100 requests per windowMs
    message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

// Request validation middleware
const validatePredictionInput = (req, res, next) => {
    const requiredFields = [
        'air_temperature',
        'process_temperature',
        'rotational_speed',
        'torque',
        'tool_wear',
        'type_H',
        'type_L',
        'type_M'
    ];

    const data = req.body;

    // Check if all required fields are present
    const missingFields = requiredFields.filter(field => !(field in data));

    if (missingFields.length > 0) {
        return res.status(400).json({
            success: false,
            error: 'Missing required fields',
            missing_fields: missingFields,
            required_fields: requiredFields
        });
    }

    // Validate data types
    const numericFields = [
        'air_temperature',
        'process_temperature',
        'rotational_speed',
        'torque',
        'tool_wear'
    ];

    const binaryFields = ['type_H', 'type_L', 'type_M'];

    for (const field of numericFields) {
        if (typeof data[field] !== 'number' || isNaN(data[field])) {
            return res.status(400).json({
                success: false,
                error: `Field '${field}' must be a valid number`
            });
        }
    }

    for (const field of binaryFields) {
        if (![0, 1].includes(data[field])) {
            return res.status(400).json({
                success: false,
                error: `Field '${field}' must be 0 or 1`
            });
        }
    }

    // Validate that exactly one type is selected
    const typeSum = data.type_H + data.type_L + data.type_M;
    if (typeSum !== 1) {
        return res.status(400).json({
            success: false,
            error: 'Exactly one type (H, L, or M) must be selected (value of 1)'
        });
    }

    next();
};

// Health check endpoint
app.get('/api/health', async (req, res) => {
    try {
        const flaskResponse = await axios.get(`${FLASK_URL}/health`, {
            timeout: 5002
        });

        res.json({
            success: true,
            express_server: 'healthy',
            flask_server: flaskResponse.data,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        res.status(503).json({
            success: false,
            express_server: 'healthy',
            flask_server: 'unhealthy',
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

// Model information endpoint
app.get('/api/model/info', async (req, res) => {
    try {
        const response = await axios.get(`${FLASK_URL}/model/info`, {
            timeout: 10000
        });

        res.json({
            success: true,
            data: response.data,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        console.error('Error fetching model info:', error.message);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch model information',
            message: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

// Single prediction endpoint
app.post('/api/predict', validatePredictionInput, async (req, res) => {
    try {
        const inputData = {
            air_temperature: req.body.air_temperature,
            process_temperature: req.body.process_temperature,
            rotational_speed: req.body.rotational_speed,
            torque: req.body.torque,
            tool_wear: req.body.tool_wear,
            type_H: req.body.type_H,
            type_L: req.body.type_L,
            type_M: req.body.type_M
        };

        const response = await axios.post(
            `${FLASK_URL}/predict`,
            inputData,
            {
                timeout: 30020,
                headers: { 'Content-Type': 'application/json' }
            }
        );

        // Format response
        const prediction = response.data.prediction;
        
        res.json({
            success: true,
            data: {
                predicted_failure_type: prediction.predicted_class,
                confidence: (prediction.probability * 100).toFixed(2) + '%',
                probability: prediction.probability,
                reconstruction_error: prediction.reconstruction_error,
                all_probabilities: prediction.all_probabilities,
                is_anomaly: prediction.reconstruction_error > 0.1, // Threshold can be adjusted
                device_used: prediction.device_used
            },
            input: inputData,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        console.error('Prediction error:', error.message);
        
        if (error.response) {
            // Flask server responded with error
            res.status(error.response.status).json({
                success: false,
                error: 'Prediction failed',
                message: error.response.data.message || error.message,
                timestamp: new Date().toISOString()
            });
        } else if (error.request) {
            // No response from Flask server
            res.status(503).json({
                success: false,
                error: 'Flask server unavailable',
                message: 'Could not connect to ML service',
                timestamp: new Date().toISOString()
            });
        } else {
            // Other errors
            res.status(500).json({
                success: false,
                error: 'Internal server error',
                message: error.message,
                timestamp: new Date().toISOString()
            });
        }
    }
});

// Batch prediction endpoint
app.post('/api/predict/batch', async (req, res) => {
    try {
        const { samples } = req.body;

        if (!samples || !Array.isArray(samples) || samples.length === 0) {
            return res.status(400).json({
                success: false,
                error: 'Invalid input',
                message: 'Request body must contain a non-empty "samples" array'
            });
        }

        // Validate each sample
        const requiredFields = [
            'air_temperature',
            'process_temperature',
            'rotational_speed',
            'torque',
            'tool_wear',
            'type_H',
            'type_L',
            'type_M'
        ];

        for (let i = 0; i < samples.length; i++) {
            const sample = samples[i];
            const missingFields = requiredFields.filter(field => !(field in sample));

            if (missingFields.length > 0) {
                return res.status(400).json({
                    success: false,
                    error: `Sample ${i} is missing required fields`,
                    missing_fields: missingFields,
                    sample_index: i
                });
            }
        }

        const response = await axios.post(
            `${FLASK_URL}/predict/batch`,
            { samples },
            {
                timeout: 60000,
                headers: { 'Content-Type': 'application/json' }
            }
        );

        // Format response
        const predictions = response.data.predictions.map((pred, index) => ({
            sample_index: index,
            predicted_failure_type: pred.predicted_class,
            confidence: (pred.probability * 100).toFixed(2) + '%',
            probability: pred.probability,
            reconstruction_error: pred.reconstruction_error,
            all_probabilities: pred.all_probabilities,
            is_anomaly: pred.reconstruction_error > 0.1
        }));

        res.json({
            success: true,
            data: {
                predictions,
                total_samples: predictions.length
            },
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        console.error('Batch prediction error:', error.message);
        
        if (error.response) {
            res.status(error.response.status).json({
                success: false,
                error: 'Batch prediction failed',
                message: error.response.data.message || error.message,
                timestamp: new Date().toISOString()
            });
        } else if (error.request) {
            res.status(503).json({
                success: false,
                error: 'Flask server unavailable',
                message: 'Could not connect to ML service',
                timestamp: new Date().toISOString()
            });
        } else {
            res.status(500).json({
                success: false,
                error: 'Internal server error',
                message: error.message,
                timestamp: new Date().toISOString()
            });
        }
    }
});

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        message: 'Predictive Maintenance API',
        version: '1.0.0',
        endpoints: {
            health: 'GET /api/health',
            model_info: 'GET /api/model/info',
            predict: 'POST /api/predict',
            batch_predict: 'POST /api/predict/batch'
        },
        documentation: '/api/docs'
    });
});

// API documentation endpoint
app.get('/api/docs', (req, res) => {
    res.json({
        title: 'Predictive Maintenance API Documentation',
        version: '1.0.0',
        description: 'API for predicting machine failures using VAE-based classification',
        base_url: `http://localhost:${PORT}`,
        endpoints: [
            {
                method: 'GET',
                path: '/api/health',
                description: 'Check health status of both Express and Flask servers',
                response: {
                    success: true,
                    express_server: 'healthy',
                    flask_server: { status: 'healthy', model_loaded: true }
                }
            },
            {
                method: 'GET',
                path: '/api/model/info',
                description: 'Get information about the ML model',
                response: {
                    success: true,
                    data: {
                        input_dim: 8,
                        num_classes: 6,
                        classes: ['No Failure', 'Heat Dissipation Failure', 'etc...'],
                        feature_names: ['air_temperature', 'process_temperature', '...']
                    }
                }
            },
            {
                method: 'POST',
                path: '/api/predict',
                description: 'Predict failure type for a single machine sample',
                request_body: {
                    air_temperature: 300.0,
                    process_temperature: 310.0,
                    rotational_speed: 1500,
                    torque: 40.0,
                    tool_wear: 100,
                    type_H: 0,
                    type_L: 1,
                    type_M: 0
                },
                response: {
                    success: true,
                    data: {
                        predicted_failure_type: 'No Failure',
                        confidence: '95.50%',
                        probability: 0.955,
                        reconstruction_error: 0.02,
                        is_anomaly: false
                    }
                }
            },
            {
                method: 'POST',
                path: '/api/predict/batch',
                description: 'Predict failure types for multiple machine samples',
                request_body: {
                    samples: [
                        {
                            air_temperature: 300.0,
                            process_temperature: 310.0,
                            rotational_speed: 1500,
                            torque: 40.0,
                            tool_wear: 100,
                            type_H: 0,
                            type_L: 1,
                            type_M: 0
                        }
                    ]
                },
                response: {
                    success: true,
                    data: {
                        predictions: [],
                        total_samples: 1
                    }
                }
            }
        ],
        input_fields: {
            air_temperature: 'Air temperature in Kelvin (K)',
            process_temperature: 'Process temperature in Kelvin (K)',
            rotational_speed: 'Rotational speed in RPM',
            torque: 'Torque in Nm',
            tool_wear: 'Tool wear in minutes',
            type_H: 'High quality variant (0 or 1)',
            type_L: 'Low quality variant (0 or 1)',
            type_M: 'Medium quality variant (0 or 1)'
        },
        notes: [
            'Exactly one type (H, L, or M) must be set to 1',
            'All temperature values should be in Kelvin',
            'Reconstruction error > 0.1 indicates potential anomaly'
        ]
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        error: 'Endpoint not found',
        message: `Cannot ${req.method} ${req.path}`,
        available_endpoints: [
            'GET /',
            'GET /api/health',
            'GET /api/model/info',
            'GET /api/docs',
            'POST /api/predict',
            'POST /api/predict/batch'
        ]
    });
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    res.status(500).json({
        success: false,
        error: 'Internal server error',
        message: err.message
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`Express server running on port ${PORT}`);
    console.log(`Flask server URL: ${FLASK_URL}`);
    console.log(`API Documentation: http://localhost:${PORT}/api/docs`);
});

module.exports = app;
