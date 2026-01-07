"""
Script to generate scaler.pkl from the training data
This needs to be run once before starting the Flask server
"""
import pandas as pd
from sklearn.preprocessing import StandardScaler
import pickle
import os

def generate_scaler():
    """Generate and save StandardScaler from training data"""
    print("Loading dataset...")
    df = pd.read_csv('Dataset/predictive_maintenance.csv')
    
    # Apply same preprocessing as in training.py
    print("Preprocessing data...")
    df_failure = df[df['Target'] == 1]
    index_possible_failure = df_failure[df_failure['Failure Type'] == 'No Failure'].index
    df.drop(index_possible_failure, axis=0, inplace=True)
    
    df.drop(["UDI", "Product ID"], axis=1, inplace=True)
    df = pd.get_dummies(df, columns=['Type'], prefix='', prefix_sep='', drop_first=False)
    
    dummy_columns = [col for col in df.columns if col in ['H', 'L', 'M']]
    df[dummy_columns] = df[dummy_columns].astype(float)
    
    # Extract features from normal behavior data
    feature_columns = [
        'Air temperature [K]', 'Process temperature [K]', 
        'Rotational speed [rpm]', 'Torque [Nm]', 
        'Tool wear [min]', 'H', 'L', 'M'
    ]
    
    normal_behaviour_data = df[df['Target'] == 0]
    X = normal_behaviour_data[feature_columns].values
    
    # Fit StandardScaler
    print("Fitting StandardScaler...")
    scaler = StandardScaler()
    scaler.fit(X)
    
    # Save scaler
    output_path = 'Models/scaler.pkl'
    os.makedirs('Models', exist_ok=True)
    
    print(f"Saving scaler to {output_path}...")
    with open(output_path, 'wb') as f:
        pickle.dump(scaler, f)
    
    print("✓ Scaler saved successfully!")
    print(f"  Mean: {scaler.mean_}")
    print(f"  Scale: {scaler.scale_}")
    
    return scaler

if __name__ == "__main__":
    print("=" * 50)
    print("Generating StandardScaler for Flask Server")
    print("=" * 50)
    print()
    
    try:
        scaler = generate_scaler()
        print()
        print("=" * 50)
        print("SUCCESS: Scaler generated and saved!")
        print("=" * 50)
    except Exception as e:
        print()
        print("=" * 50)
        print(f"ERROR: {str(e)}")
        print("=" * 50)
        raise
