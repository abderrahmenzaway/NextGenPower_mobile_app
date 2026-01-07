import psycopg2
import time
import random
import os

# PostgreSQL connection parameters from environment variables
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': os.getenv('DB_PORT', '5432'),
    'database': os.getenv('DB_NAME', 'ecoguardians'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', 'postgres')
}

def add_record():
    """
    Add a record to the energy table with a random mwh value and current timestamp.
    """
    conn = None
    try:
        # Connect to the database
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        # Generate random mwh and current timestamp
        mwh = random.randint(50, 500)  # Random mwh value between 50 and 500
        current_time = int(time.time())  # Current Unix timestamp in seconds
        
        # Insert a new record
        cursor.execute("INSERT INTO energy (mwh, time) VALUES (%s, %s)", (mwh, current_time))
        
        # Commit and close
        conn.commit()
        print(f"Added record: mwh={mwh}, time={current_time}")
    except psycopg2.OperationalError as e:
        print(f"Database connection error: {e}")
        print("Please check if PostgreSQL is running and connection parameters are correct.")
    except psycopg2.IntegrityError as e:
        print(f"Data integrity error: {e}")
    except psycopg2.Error as e:
        print(f"Database error: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    print("Starting to add records every 10 seconds. Press Ctrl+C to stop.")
    try:
        while True:
            add_record()
            time.sleep(10)  # Wait for 10 seconds
    except KeyboardInterrupt:
        print("\nStopped adding records.")
