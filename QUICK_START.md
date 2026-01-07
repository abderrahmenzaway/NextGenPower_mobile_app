# Quick Start Guide - Updated Trading Platform

## 🚀 Getting Started

### Prerequisites

Before starting, ensure you have:
- **Node.js** (v16 or higher) and npm
- **PostgreSQL** (v12 or higher) - See PostgreSQL Setup below
- **Hedera Testnet Account** - Get one from https://portal.hedera.com/register
- **Flutter SDK** (if using the mobile app)

### PostgreSQL Setup

#### Install PostgreSQL

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

**macOS (using Homebrew):**
```bash
brew install postgresql@15
brew services start postgresql@15
```

**Windows:**
Download and install from: https://www.postgresql.org/download/windows/

#### Create Database

```bash
# Login to PostgreSQL (Ubuntu/Debian/macOS)
sudo -u postgres psql

# OR on Windows, open SQL Shell (psql) from Start Menu
# Then run:

CREATE DATABASE ecoguardians;

# (Optional) Create a dedicated user
CREATE USER ecouser WITH PASSWORD 'yourpassword';
GRANT ALL PRIVILEGES ON DATABASE ecoguardians TO ecouser;

# Exit
\q
```

### Backend Setup

1. **Install Dependencies**
```bash
cd blockchain/hedera-energy-trading
npm install
```

2. **Configure Environment**
```bash
# Copy the example environment file
cp .env.example .env

# Edit .env and add your credentials:
# 
# Hedera Configuration:
# MY_ACCOUNT_ID=0.0.YOUR_ACCOUNT_ID
# MY_PRIVATE_KEY=your_private_key
# TEC_TOKEN_ID=0.0.YOUR_TOKEN_ID
#
# PostgreSQL Configuration:
# DB_HOST=localhost
# DB_PORT=5432
# DB_NAME=ecoguardians
# DB_USER=postgres
# DB_PASSWORD=postgres
```

3. **Start the Server**
```bash
npm start
```

The server will start on `http://localhost:3000`

### Flutter App Setup

1. **Install Flutter Dependencies**
```bash
cd flutter_application_1
flutter pub get
```

2. **Update API Configuration**
Edit `lib/services/api_service.dart` if needed:
```dart
static String baseUrl = 'http://localhost:3000';
```

3. **Run the App**
```bash
flutter run
```

## 📱 Using the App

### First-Time Registration

1. Open the app
2. Click on **"Register Factory"** tab
3. Fill in the registration form:
   - **Factory ID**: Unique identifier (e.g., F-001)
   - **Factory Name**: Your factory name
   - **Password**: Secure password (min 6 chars)
   - **Confirm Password**: Re-enter password
   - **Initial Energy Balance**: Starting kWh (e.g., 1000)
   - **Initial TEC Balance**: Starting currency (e.g., 500)
   - **Energy Type**: Select your energy source
4. Click **"Register Factory"**
5. You'll be automatically logged in

### Logging In

1. Open the app
2. Enter your **Factory ID**
3. Enter your **Password**
4. Click **"Login to Dashboard"**

### Creating Trading Offers

1. Navigate to the **"Offers"** tab (bottom navigation)
2. Click the **+** button in the top right
3. Fill in the offer details:
   - **Offer Type**: Sell or Buy
   - **Target Factory ID**: (optional) Specific factory or leave empty for open offer
   - **Amount**: Energy in kWh
   - **Price per kWh**: Price in TEC
4. Click **"Create"**

### Viewing Your Blockchain Info

1. Go to **Dashboard**
2. Click the **blockchain icon** (⚛️) in the top right
3. View your:
   - Real TEC balance
   - Hedera account ID
   - Token information

### Checking Your Profile

1. Go to **Dashboard**
2. Click the **profile icon** (👤) in the top right
3. View:
   - Factory details
   - Hedera account ID
   - Real TEC balance
   - Energy statistics
   - Settings

## 🔑 API Endpoints Quick Reference

### Authentication
```bash
# Register a new factory
POST http://localhost:3000/api/factory/register
Content-Type: application/json

{
  "factoryId": "F-001",
  "name": "Solar Factory",
  "password": "securePassword123",
  "initialBalance": 1000,
  "energyType": "Solar",
  "currencyBalance": 500
}

# Login
POST http://localhost:3000/api/factory/login
Content-Type: application/json

{
  "factoryId": "F-001",
  "password": "securePassword123"
}
```

### Factory Information
```bash
# Get factory details
GET http://localhost:3000/api/factory/F-001

# Get all factories
GET http://localhost:3000/api/factories
```

### Trading
```bash
# Create a trade offer
POST http://localhost:3000/api/trade/create
Content-Type: application/json

{
  "tradeId": "TRADE-123456789",
  "sellerId": "F-001",
  "buyerId": "F-002",
  "amount": 50,
  "pricePerUnit": 0.10
}

# Execute a trade
POST http://localhost:3000/api/trade/execute
Content-Type: application/json

{
  "tradeId": "TRADE-123456789"
}
```

## 🛠️ Troubleshooting

### "connect ECONNREFUSED 127.0.0.1:5432" or PostgreSQL Connection Error
**Solutions**:
1. Verify PostgreSQL is running:
   ```bash
   # Ubuntu/Debian
   sudo systemctl status postgresql
   sudo systemctl start postgresql
   
   # macOS
   brew services list | grep postgresql
   brew services start postgresql@15
   ```

2. Verify database exists:
   ```bash
   sudo -u postgres psql -l | grep ecoguardians
   # If not found, create it:
   sudo -u postgres psql -c "CREATE DATABASE ecoguardians;"
   ```

3. Check credentials in `.env` file match your PostgreSQL setup

4. Test PostgreSQL connection:
   ```bash
   psql -h localhost -p 5432 -U postgres -d ecoguardians
   ```

### "Cannot find module 'bcrypt'"
```bash
cd blockchain/hedera-energy-trading
npm install bcrypt
```

### "Port 3000 already in use"
Either stop the existing process or change the port:
```bash
PORT=3001 npm start
```
Then update the Flutter app's API base URL.

### "Factory already exists"
This means a factory with that ID is already registered. Either:
- Use a different Factory ID
- Delete data from PostgreSQL to start fresh:
  ```bash
  sudo -u postgres psql -d ecoguardians -c "TRUNCATE factories, trades, transaction_history CASCADE;"
  ```

### "Invalid factory ID or password"
- Double-check your Factory ID (case-sensitive)
- Ensure you're using the correct password
- If you forgot your password, you'll need to re-register

### No Hedera Account ID showing
This means the Hedera integration is not configured or the factory was created before the update. To fix:
1. Configure your `.env` file with Hedera credentials
2. Re-register your factory

## 📊 Features Overview

### ✅ What's Working
- Secure password authentication
- Real Hedera blockchain integration
- TEC token balance display
- Manual trade creation
- Factory registration with Hedera accounts
- Professional UI/UX

### ⚠️ Important Notes
- All passwords are securely hashed (never stored in plain text)
- Each factory gets its own Hedera account
- Mock/forced trades have been removed
- Users must manually create all trading offers
- Empty states show helpful messages when no data is available

## 🔐 Security Best Practices

1. **Use strong passwords** (at least 8-10 characters with mixed case, numbers, symbols)
2. **Never share your Factory ID and password**
3. **Keep your Hedera private keys secure** (stored in `.env`, never commit to git)
4. **Backup your database** regularly:
   ```bash
   pg_dump -U postgres ecoguardians > backup.sql
   ```
5. **Use HTTPS in production** (not HTTP)

## 📞 Need Help?

- Check the detailed documentation: `blockchain/hedera-energy-trading/README.md`
- Review PostgreSQL setup: `POSTGRESQL_MIGRATION.md`
- Review the API endpoints in `server.js`
- Ensure dependencies are installed: `npm list` and `flutter pub deps`
- Check server logs for detailed error messages
- Verify your `.env` configuration

## 🎯 Next Steps

1. Register multiple factories to test trading
2. Create various trade offers (buy and sell)
3. Execute trades between factories
4. Monitor your TEC balance changes
5. Explore the blockchain screen for transaction details

Happy Trading! 🚀⚡
