# Renewable Energy Tokenization System

## Overview

This project implements a blockchain-based system for tracking and rewarding renewable energy production using Hedera Hashgraph and ECoin tokens. The system automatically records energy generation and transfers corresponding tokens to the energy producer.

## Prerequisites

### Hedera Hashgraph Account Creation

Before setting up the project, you must create a Hedera Testnet account:

1. **Create Hedera Account**
   - Visit the Hedera Developer Portal: [https://portal.hedera.com/register](https://portal.hedera.com/register)
   - Click "Create a Free Testnet Account"
   - Complete the registration process

2. **Retrieve Account Credentials**
   - Log in to the Hedera Developer Portal
   - Navigate to the "Accounts" section
   - Click "Create Account" to generate a new Hedera Testnet account
   - You will receive two critical pieces of information:
     a. **Account ID**: A string in the format `0.0.XXXXXXX`
     b. **Private Key**: A long hexadecimal string starting with `0x`

3. **Prepare .env File**
   - Create a file named `.env` in your project's root directory
   - Add your credentials in the following format:
     ```
     MY_ACCOUNT_ID=your_account_id_here
     MY_PRIVATE_KEY=your_private_key_here
     ```

   **Important Security Notes:**
   - Keep your private key confidential
   - Never share your `.env` file
   - Add `.env` to your `.gitignore` file to prevent accidental commits

### System Requirements
- Node.js (v16 or higher)
- npm (Node Package Manager)
- PostgreSQL (v12 or higher)
- Hedera Hashgraph Testnet Account

### Required Dependencies
- @hashgraph/sdk
- dotenv
- express
- pg (PostgreSQL driver)

## Configuration

### 1. Environment Setup

1. Create a `.env` file in the project root with the following variables:
   ```
   MY_ACCOUNT_ID=your_hedera_account_id
   MY_PRIVATE_KEY=your_hedera_private_key
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=ecoguardians
   DB_USER=postgres
   DB_PASSWORD=postgres
   ```

2. Replace the Hedera credentials with your actual Testnet credentials.

### 2. Database Preparation

Before running the application, ensure your PostgreSQL database is set up:

1. Create the database:
   ```bash
   createdb ecoguardians
   ```

2. Run the schema file to create tables:
   ```bash
   psql -d ecoguardians -f schema.sql
   ```

The schema creates the following table:
```sql
CREATE TABLE energy (
    id SERIAL PRIMARY KEY,
    mwh INTEGER NOT NULL,
    time INTEGER NOT NULL
);
```

## Installation

1. Clone the repository
```bash
git clone <your-repository-url>
cd <project-directory>
```

2. Install dependencies
```bash
npm install
```

## Running the Application

### Start the Server
```bash
node server.js
```
- The server will start on port 3000
- It listens for POST requests to `/send` endpoint

### Start the Token Generation Script
```bash
node index.js
```
- Automatically creates ECoin token
- Sets up token transfer mechanism
- Runs token transfers every 60 seconds

## API Endpoint

### Send Energy Data
- **Endpoint:** `/send`
- **Method:** POST
- **Payload Example:**
  ```json
  {
    "mwh": 5.5,
    "currentTime": 1623456789
  }
  ```

## Token Mechanism

- Token Name: ECoin
- Token Symbol: EC
- Conversion Rate: 1 mWh = 100 ECoin
- Token Type: Fungible Common
- Initial Supply: 100,000 tokens

## Monitoring

- Token transfers can be tracked via: https://explorer.arkhia.io/testnet/token/[TOKEN_ID]

## Security Considerations

- Keep your `.env` file confidential
- Use strong, unique Hedera account credentials
- Implement additional authentication for the API endpoint in production

## Troubleshooting

- Ensure Hedera Testnet connectivity
- Verify PostgreSQL database is running and accessible
- Check PostgreSQL connection parameters in `.env`
- Check environment variable configuration
