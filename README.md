# EcoGuardians - Industrial Energy Trading & Monitoring Platform

A comprehensive **Hedera Hashgraph** blockchain-based energy trading system with AI-powered energy monitoring, designed for industrial zones and factories.

## 🌟 Overview

EcoGuardians is a complete solution for managing and trading energy in industrial environments. The system combines:

- **Blockchain-based Energy Trading**: Using Hedera Hashgraph and TEC (Tunisian Energy Coin) token
- **AI Energy Monitoring**: Machine learning models for energy disaggregation and demand forecasting
- **Mobile Application**: Flutter-based app for factory management and trading
- **IoT Integration**: Arduino and sensor interfaces for real-time energy monitoring

## 📁 Project Structure

```
EcoGuardians-main/
├── blockchain/
│   ├── hedera-energy-trading/    # Main trading platform (Node.js + PostgreSQL)
│   └── files/                    # Energy data recording system
├── flutter_application_1/         # Mobile app for factory management
├── AI-models/
│   ├── Desagrigation-model/      # NILM energy disaggregation
│   ├── Energy-demand-Model/      # Energy demand forecasting
│   ├── Failure-detection/        # Equipment failure detection
│   └── workers-safety-detection/ # Safety monitoring
├── other-interfaces/
│   └── Arduino-code+interfaces/  # IoT sensor integration
└── docs/                          # Documentation (QUICK_START.md, etc.)
```

## 🚀 Quick Start

### Prerequisites

Before you begin, ensure you have:

1. **Node.js** (v16 or higher) - [Download](https://nodejs.org/)
2. **PostgreSQL** (v12 or higher) - Required for the trading platform
3. **Hedera Testnet Account** - [Register](https://portal.hedera.com/register)
4. **Flutter SDK** (optional, for mobile app) - [Install](https://flutter.dev/docs/get-started/install)

### 1. Setup PostgreSQL Database

#### Install PostgreSQL

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

**macOS:**
```bash
brew install postgresql@15
brew services start postgresql@15
```

**Windows:**
Download from [postgresql.org](https://www.postgresql.org/download/windows/)

#### Create Database

```bash
# Login to PostgreSQL
sudo -u postgres psql

# Create database
CREATE DATABASE ecoguardians;

# Exit
\q
```

### 2. Setup Energy Trading Platform

```bash
cd blockchain/hedera-energy-trading

# Install dependencies
npm install

# Copy and configure environment
cp .env.example .env
# Edit .env with your Hedera credentials and PostgreSQL settings

# Initialize TEC token
npm run init

# Start the server
npm start
```

The API will be available at `http://localhost:3000`

### 3. Setup Flutter Mobile App (Optional)

```bash
cd flutter_application_1

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## 📚 Documentation

- **[QUICK_START.md](QUICK_START.md)** - Comprehensive getting started guide
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture and design
- **[POSTGRESQL_MIGRATION.md](POSTGRESQL_MIGRATION.md)** - Database setup and migration guide
- **[blockchain/hedera-energy-trading/README.md](blockchain/hedera-energy-trading/README.md)** - Detailed API documentation

## 🔑 Key Features

### Energy Trading Platform
- **TEC Token**: Fungible token (Tunisian Energy Coin) for energy payments
- **Hedera Hashgraph**: Fast, fair, and secure distributed ledger
- **Real Transactions**: Each factory has its own Hedera account
- **REST API**: Easy integration with factory systems
- **PostgreSQL Database**: Production-grade data storage

### Mobile Application
- **Secure Authentication**: Password-protected factory accounts
- **Real-time Balance**: View energy and TEC token balances
- **Trade Management**: Create and execute energy trades
- **Blockchain Integration**: Direct Hedera network access
- **Professional UI**: Modern, intuitive interface

### AI Models
- **Energy Disaggregation**: NILM for appliance-level monitoring
- **Demand Forecasting**: Predict future energy consumption
- **Failure Detection**: Identify equipment anomalies
- **Safety Monitoring**: Worker safety detection

## 🔐 Security Features

- **Password Hashing**: bcrypt for secure password storage
- **Private Key Management**: Secure storage in .env files
- **ABFT Consensus**: Hedera's asynchronous Byzantine Fault Tolerance
- **Transaction Signatures**: Cryptographically signed transactions
- **Audit Trail**: Complete transaction history on blockchain

## 🛠️ Technology Stack

- **Blockchain**: Hedera Hashgraph (HTS, HCS)
- **Backend**: Node.js, Express.js
- **Database**: PostgreSQL
- **Frontend**: Flutter (Dart)
- **AI/ML**: Python, TensorFlow, PyTorch
- **IoT**: Arduino, various sensors

## 📊 API Endpoints

### Authentication
- `POST /api/factory/register` - Register a new factory
- `POST /api/factory/login` - Login to factory account

### Energy Operations
- `POST /api/energy/mint` - Mint energy tokens (surplus generation)
- `POST /api/energy/transfer` - Transfer energy between factories

### Trading
- `POST /api/trade/create` - Create a trade offer
- `POST /api/trade/execute` - Execute a trade
- `GET /api/trade/:tradeId` - Get trade details

### Query Endpoints
- `GET /api/factory/:factoryId` - Get factory information
- `GET /api/factories` - List all factories
- `GET /api/factory/:factoryId/balance` - Get factory balance
- `GET /api/factory/:factoryId/history` - Get transaction history

## 🐛 Troubleshooting

### PostgreSQL Connection Error (ECONNREFUSED)

**Error**: `connect ECONNREFUSED 127.0.0.1:5432`

**Solutions**:
1. Verify PostgreSQL is running:
   ```bash
   sudo systemctl status postgresql
   sudo systemctl start postgresql  # If not running
   ```

2. Check database exists:
   ```bash
   sudo -u postgres psql -l | grep ecoguardians
   ```

3. Verify credentials in `.env` file

4. Test connection:
   ```bash
   psql -h localhost -p 5432 -U postgres -d ecoguardians
   ```

See [QUICK_START.md](QUICK_START.md) for more troubleshooting help.

## 🌐 Monitoring

### View Transactions on Hedera Network
- Testnet: `https://hashscan.io/testnet/transaction/{transactionId}`
- Mainnet: `https://hashscan.io/mainnet/transaction/{transactionId}`

### View TEC Token
```
https://hashscan.io/testnet/token/{YOUR_TOKEN_ID}
```

## 🤝 Contributing

This is a demonstration project for industrial energy trading and monitoring. Future enhancements:

- Integration with Hedera smart contracts (HCS)
- Advanced market making algorithms
- Real-time IoT sensor integration
- Enhanced AI models for predictive maintenance
- Multi-region energy trading
- Carbon credit trading

## 📝 License

Apache-2.0

## 📞 Support

For detailed setup instructions and troubleshooting:
- Read [QUICK_START.md](QUICK_START.md)
- Check [blockchain/hedera-energy-trading/README.md](blockchain/hedera-energy-trading/README.md)
- Review [POSTGRESQL_MIGRATION.md](POSTGRESQL_MIGRATION.md) for database issues

## 🎯 Getting Started Checklist

- [ ] Install PostgreSQL
- [ ] Create `ecoguardians` database
- [ ] Install Node.js and dependencies
- [ ] Create Hedera testnet account
- [ ] Configure `.env` file
- [ ] Initialize TEC token
- [ ] Start the API server
- [ ] (Optional) Setup Flutter mobile app
- [ ] Register your first factory
- [ ] Create and execute a trade

---

**Built with Hedera Hashgraph for sustainable energy trading** ⚡🌱
