import os
import pickle
import numpy as np
import pandas as pd
import torch
import torch.nn as nn
from flask import Flask, request, jsonify
from flask_cors import CORS
import sys

# Add parent directory to path to import model classes
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

class VAE(nn.Module):
    """Variational Autoencoder (VAE) for feature learning"""
    def __init__(self, input_dim, hidden_dim, latent_dim):
        super(VAE, self).__init__()
        
        # Encoder
        self.encoder = nn.Sequential(
            nn.Linear(input_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.ReLU()
        )
        
        # Latent space layers
        self.fc_mu = nn.Linear(hidden_dim, latent_dim)
        self.fc_var = nn.Linear(hidden_dim, latent_dim)
        
        # Decoder
        self.decoder = nn.Sequential(
            nn.Linear(latent_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, input_dim)
        )
    
    def reparameterize(self, mu, log_var):
        """Reparameterization trick to sample from N(mu, var)"""
        std = torch.exp(0.5 * log_var)
        eps = torch.randn_like(std)
        return mu + eps * std
    
    def forward(self, x):
        # Encode
        h = self.encoder(x)
        
        # Get mu and log variance
        mu = self.fc_mu(h)
        log_var = self.fc_var(h)
        
        # Reparameterize
        z = self.reparameterize(mu, log_var)
        
        # Decode
        x_recon = self.decoder(z)
        
        return x_recon, mu, log_var

class VAEClassifier(nn.Module):
    """Classifier that uses VAE's latent representation"""
    def __init__(self, vae, num_classes):
        super(VAEClassifier, self).__init__()
        
        # Freeze VAE parameters
        for param in vae.parameters():
            param.requires_grad = False
        
        self.vae = vae
        
        # Classification layers
        self.classifier = nn.Sequential(
            nn.Linear(vae.fc_mu.out_features, 64),
            nn.ReLU(),
            nn.Linear(64, num_classes)
        )
    
    def forward(self, x):
        # Get latent representation through VAE
        h = self.vae.encoder(x)
        mu = self.vae.fc_mu(h)
        
        # Classify
        return self.classifier(mu)

class PredictiveMaintenanceModel:
    def __init__(self, models_dir='../Models'):
        """Initialize the Predictive Maintenance Model"""
        # Device configuration
        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        
        # Model hyperparameters
        self.input_dim = 8
        self.hidden_dim = 128
        self.latent_dim = 64
        self.num_classes = 6
        
        # Load preprocessing artifacts
        self.load_preprocessing_artifacts(models_dir)
        
        # Initialize and load models
        self.load_models(models_dir)
    
    def load_preprocessing_artifacts(self, models_dir):
        """Load saved preprocessing artifacts"""
        # Load StandardScaler
        scaler_path = os.path.join(models_dir, 'scaler.pkl')
        if os.path.exists(scaler_path):
            with open(scaler_path, 'rb') as f:
                self.scaler = pickle.load(f)
        else:
            raise FileNotFoundError(f"StandardScaler not found at {scaler_path}")
        
        # Load LabelEncoder
        label_encoder_path = os.path.join(models_dir, 'label_encoder.pkl')
        if os.path.exists(label_encoder_path):
            with open(label_encoder_path, 'rb') as f:
                self.label_encoder = pickle.load(f)
        else:
            raise FileNotFoundError(f"Label Encoder not found at {label_encoder_path}")
    
    def load_models(self, models_dir):
        """Load pre-trained VAE and Classifier models"""
        # Initialize VAE
        self.vae = VAE(self.input_dim, self.hidden_dim, self.latent_dim).to(self.device)
        vae_path = os.path.join(models_dir, 'vae_model.pth')
        if os.path.exists(vae_path):
            self.vae.load_state_dict(torch.load(vae_path, map_location=self.device))
        else:
            raise FileNotFoundError(f"VAE model not found at {vae_path}")
        
        # Initialize Classifier
        self.classifier = VAEClassifier(self.vae, self.num_classes).to(self.device)
        classifier_path = os.path.join(models_dir, 'classifier_model.pth')
        if os.path.exists(classifier_path):
            self.classifier.load_state_dict(torch.load(classifier_path, map_location=self.device))
        else:
            raise FileNotFoundError(f"Classifier model not found at {classifier_path}")
        
        # Set models to evaluation mode
        self.vae.eval()
        self.classifier.eval()
    
    def preprocess_data(self, data):
        """Preprocess input data"""
        # Scale the data
        scaled_data = self.scaler.transform(data)
        
        # Convert to PyTorch tensor
        return torch.tensor(scaled_data, dtype=torch.float32).to(self.device)
    
    def predict_single(self, data):
        """Predict anomaly type for a single input"""
        # Preprocess data
        input_tensor = self.preprocess_data(data)
        
        # Get classifier outputs
        with torch.no_grad():
            outputs = self.classifier(input_tensor)
            probabilities = torch.softmax(outputs, dim=1)
            predicted_class_idx = torch.argmax(outputs, dim=1).cpu().numpy()
        
        # Decode predictions
        predicted_class = self.label_encoder.classes_[predicted_class_idx[0]]
        prediction_prob = probabilities[0, predicted_class_idx[0]].item()
        
        # Get all class probabilities
        all_probabilities = {}
        for idx, class_name in enumerate(self.label_encoder.classes_):
            all_probabilities[class_name] = float(probabilities[0, idx].item())
        
        # Reconstruction for anomaly detection
        with torch.no_grad():
            x_recon, _, _ = self.vae(input_tensor)
            reconstruction_error = nn.functional.mse_loss(
                x_recon, input_tensor, reduction='none'
            ).mean(dim=1).cpu().numpy()
        
        return {
            'predicted_class': predicted_class,
            'probability': prediction_prob,
            'all_probabilities': all_probabilities,
            'reconstruction_error': float(reconstruction_error[0]),
            'device_used': str(self.device)
        }
    
    def predict_batch(self, data):
        """Predict anomalies for a batch of data"""
        results = []
        for i in range(len(data)):
            sample = data[i:i+1]
            result = self.predict_single(sample)
            results.append(result)
        return results

# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Global model instance
model = None

def initialize_model():
    """Initialize the model on startup"""
    global model
    try:
        models_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'Models')
        model = PredictiveMaintenanceModel(models_dir=models_dir)
        print("Model loaded successfully!")
        print(f"Using device: {model.device}")
        print(f"Available classes: {model.label_encoder.classes_}")
    except Exception as e:
        print(f"Error loading model: {str(e)}")
        raise

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'model_loaded': model is not None,
        'device': str(model.device) if model else None
    }), 200

@app.route('/predict', methods=['POST'])
def predict():
    """
    Predict endpoint
    
    Expected input format:
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
    """
    try:
        if model is None:
            return jsonify({'error': 'Model not loaded'}), 500
        
        # Get JSON data
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Extract features in the correct order
        feature_names = [
            'air_temperature', 'process_temperature', 'rotational_speed',
            'torque', 'tool_wear', 'type_H', 'type_L', 'type_M'
        ]
        
        # Validate all required features are present
        missing_features = [f for f in feature_names if f not in data]
        if missing_features:
            return jsonify({
                'error': 'Missing required features',
                'missing': missing_features
            }), 400
        
        # Create numpy array with features in correct order
        features = np.array([[data[f] for f in feature_names]])
        
        # Make prediction
        result = model.predict_single(features)
        
        return jsonify({
            'success': True,
            'prediction': result,
            'input_features': {k: data[k] for k in feature_names}
        }), 200
        
    except Exception as e:
        return jsonify({
            'error': 'Prediction failed',
            'message': str(e)
        }), 500

@app.route('/predict/batch', methods=['POST'])
def predict_batch():
    """
    Batch predict endpoint
    
    Expected input format:
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
            ...
        ]
    }
    """
    try:
        if model is None:
            return jsonify({'error': 'Model not loaded'}), 500
        
        # Get JSON data
        data = request.get_json()
        
        if not data or 'samples' not in data:
            return jsonify({'error': 'No samples provided'}), 400
        
        samples = data['samples']
        
        if not isinstance(samples, list) or len(samples) == 0:
            return jsonify({'error': 'Samples must be a non-empty list'}), 400
        
        # Extract features
        feature_names = [
            'air_temperature', 'process_temperature', 'rotational_speed',
            'torque', 'tool_wear', 'type_H', 'type_L', 'type_M'
        ]
        
        # Validate and prepare batch data
        batch_features = []
        for i, sample in enumerate(samples):
            missing_features = [f for f in feature_names if f not in sample]
            if missing_features:
                return jsonify({
                    'error': f'Missing features in sample {i}',
                    'missing': missing_features
                }), 400
            
            batch_features.append([sample[f] for f in feature_names])
        
        batch_array = np.array(batch_features)
        
        # Make predictions
        results = model.predict_batch(batch_array)
        
        return jsonify({
            'success': True,
            'predictions': results,
            'count': len(results)
        }), 200
        
    except Exception as e:
        return jsonify({
            'error': 'Batch prediction failed',
            'message': str(e)
        }), 500

@app.route('/model/info', methods=['GET'])
def model_info():
    """Get model information"""
    try:
        if model is None:
            return jsonify({'error': 'Model not loaded'}), 500
        
        return jsonify({
            'input_dim': model.input_dim,
            'hidden_dim': model.hidden_dim,
            'latent_dim': model.latent_dim,
            'num_classes': model.num_classes,
            'classes': model.label_encoder.classes_.tolist(),
            'device': str(model.device),
            'feature_names': [
                'air_temperature', 'process_temperature', 'rotational_speed',
                'torque', 'tool_wear', 'type_H', 'type_L', 'type_M'
            ]
        }), 200
        
    except Exception as e:
        return jsonify({
            'error': 'Failed to get model info',
            'message': str(e)
        }), 500

if __name__ == '__main__':
    # Initialize model on startup
    initialize_model()
    
    # Run Flask app
    app.run(host='0.0.0.0', port=5002, debug=False)
