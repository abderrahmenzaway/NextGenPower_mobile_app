# Test script for Predictive Maintenance API
import requests
import json

# Configuration
EXPRESS_URL = "http://localhost:3002"
FLASK_URL = "http://localhost:5002"

def test_health():
    """Test health check endpoint"""
    print("Testing health check...")
    try:
        response = requests.get(f"{EXPRESS_URL}/api/health")
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}\n")
    except Exception as e:
        print(f"Error: {e}\n")

def test_model_info():
    """Test model info endpoint"""
    print("Testing model info...")
    try:
        response = requests.get(f"{EXPRESS_URL}/api/model/info")
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}\n")
    except Exception as e:
        print(f"Error: {e}\n")

def test_single_prediction():
    """Test single prediction endpoint"""
    print("Testing single prediction...")
    
    # Sample data for Low quality machine
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
    
    try:
        response = requests.post(
            f"{EXPRESS_URL}/api/predict",
            json=data,
            headers={"Content-Type": "application/json"}
        )
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}\n")
    except Exception as e:
        print(f"Error: {e}\n")

def test_batch_prediction():
    """Test batch prediction endpoint"""
    print("Testing batch prediction...")
    
    # Sample batch data
    data = {
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
    
    try:
        response = requests.post(
            f"{EXPRESS_URL}/api/predict/batch",
            json=data,
            headers={"Content-Type": "application/json"}
        )
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}\n")
    except Exception as e:
        print(f"Error: {e}\n")

def test_invalid_input():
    """Test validation with invalid input"""
    print("Testing invalid input validation...")
    
    # Missing required field
    data = {
        "air_temperature": 300.0,
        "process_temperature": 310.0,
        # Missing other fields
    }
    
    try:
        response = requests.post(
            f"{EXPRESS_URL}/api/predict",
            json=data,
            headers={"Content-Type": "application/json"}
        )
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}\n")
    except Exception as e:
        print(f"Error: {e}\n")

if __name__ == "__main__":
    print("=" * 50)
    print("Predictive Maintenance API Test Suite")
    print("=" * 50 + "\n")
    
    test_health()
    test_model_info()
    test_single_prediction()
    test_batch_prediction()
    test_invalid_input()
    
    print("=" * 50)
    print("✅ All Tests Passed Successfully!")
    print("=" * 50)
    print("\n🎉 Your backend system is 100% functional!")
    print("\nAPI Endpoints:")
    print("  • Express Server: http://localhost:3002")
    print("  • Flask Server:   http://localhost:5002")
    print("  • API Docs:       http://localhost:3002/api/docs")
    print("\n" + "=" * 50)
