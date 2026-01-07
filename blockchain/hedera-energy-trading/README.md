# Hedera Energy Trading Network

A **Hedera Hashgraph** blockchain-based energy trading system using **TEC (Tunisian Energy Coin)** for peer-to-peer energy transactions between factories in an industrial zone.

## 🌟 Overview

This system transforms the Hyperledger Fabric energy trading network to use **Hedera Hashgraph** technology. Factories can generate, trade, and purchase energy using the TEC token as the medium of exchange.

### Key Features

- **TEC Token**: Fungible token (TEC - Tunisian Energy Coin) for energy payments
- **Hedera Hashgraph**: Fast, fair, and secure distributed ledger technology
- **Real Transactions**: Each factory has its own Hedera account with real on-chain transactions
- **Token Association**: Automatic token association when factories are registered
- **Energy Trading**: Create and execute energy trades between factories
- **Token Management**: Mint energy tokens when surplus is generated
- **Transaction History**: Complete audit trail on Hedera network (visible on HashScan explorer)
- **REST API**: Easy integration with factory management systems
- **PostgreSQL Database**: Production-grade database for factory and trade data

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   INDUSTRIAL ZONE                        │
│  Factory01  Factory02  Factory03  Factory04  ... 20     │
│   (Solar)    (Wind)   (Footstep)  (Solar)               │
└────────────────────┬────────────────────────────────────┘
                     │
           ┌─────────▼─────────┐
           │    REST API       │
           │   (Port 3000)     │
           └─────────┬─────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
   ┌────▼────────┐        ┌──────▼──────┐
   │ PostgreSQL  │        │   Hedera    │
   │  Database   │        │  Hashgraph  │
   │             │        │  Testnet    │
   └─────────────┘        └──────┬──────┘
                                 │
                          ┌──────▼──────┐
                          │ TEC Token   │
                          │  Service    │
                          └─────────────┘
```

## 📋 Prerequisites

Before you begin, ensure you have:

1. **Node.js** (v16 or higher) and npm
   - Download from: https://nodejs.org/

2. **PostgreSQL** (v12 or higher)
   - See [PostgreSQL Setup Guide](#-postgresql-setup) below for detailed installation instructions

3. **Hedera Testnet Account**
   - Visit: https://portal.hedera.com/register
   - Create a free testnet account
   - Note your Account ID (format: 0.0.XXXXXXX)
   - Note your Private Key (starts with 0x or 302e...)

## 🚀 Quick Start

### Step 1: Install Dependencies

```bash
cd blockchain/hedera-energy-trading
npm install
```

### Step 2: Configure Environment

Create a `.env` file in the project root:

```bash
cp .env.example .env
```

Edit `.env` and add your Hedera credentials and PostgreSQL configuration:

```env
# Hedera Configuration
MY_ACCOUNT_ID=0.0.XXXXXXX
MY_PRIVATE_KEY=your_private_key_here
TREASURY_ACCOUNT_ID=0.0.XXXXXXX
TEC_TOKEN_ID=
PORT=3000

# PostgreSQL Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=ecoguardians
DB_USER=postgres
DB_PASSWORD=postgres
```

### Step 3: Setup PostgreSQL Database

Before running the server, you need to install and configure PostgreSQL:

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
# Then run these commands:

# Create database
CREATE DATABASE ecoguardians;

# (Optional) Create a dedicated user
CREATE USER ecouser WITH PASSWORD 'yourpassword';
GRANT ALL PRIVILEGES ON DATABASE ecoguardians TO ecouser;

# Exit psql
\q
```

**Note**: If you create a custom user, update the `DB_USER` and `DB_PASSWORD` in your `.env` file accordingly.

The database tables will be created automatically when you start the server for the first time.

### Step 4: Create TEC Token

Run the token initialization script:

```bash
npm run init
```

This will:
- Create the TEC (Tunisian Energy Coin) token on Hedera
- Display the Token ID
- Provide an explorer link to view the token

**Important**: Copy the Token ID from the output and add it to your `.env` file:

```env
TEC_TOKEN_ID=0.0.YYYYYYY
```

### Step 5: Start the API Server

```bash
npm start
```

The API server will be available at: http://localhost:3000

## 📡 API Endpoints

### Factory Management

#### Register a New Factory
```bash
POST /api/factory/register
Content-Type: application/json

{
  "factoryId": "Factory01",
  "name": "Solar Manufacturing Plant",
  "initialBalance": 1000.0,
  "energyType": "solar",
  "currencyBalance": 500.0,
  "dailyConsumption": 800.0,
  "availableEnergy": 1200.0
}
```

This will:
1. Create a new Hedera account for the factory (with 10 HBAR initial balance)
2. Associate the factory's account with the TEC token
3. Store the factory information in the database

**Note**: Each factory gets its own Hedera account, enabling real on-chain transactions visible on the HashScan explorer.

#### Get Factory Information
```bash
GET /api/factory/Factory01
```

#### Get All Factories
```bash
GET /api/factories
```

#### Get Factory Balance
```bash
GET /api/factory/Factory01/balance
```

Response includes both energy and TEC currency balance:
```json
{
  "success": true,
  "data": {
    "factoryId": "Factory01",
    "energyBalance": 1000,
    "currencyBalance": 500
  }
}
```

### Energy Operations

#### Mint Energy Tokens (Generate Surplus)
```bash
POST /api/energy/mint
Content-Type: application/json

{
  "factoryId": "Factory01",
  "amount": 250.5
}
```

#### Transfer Energy Between Factories
```bash
POST /api/energy/transfer
Content-Type: application/json

{
  "fromFactoryId": "Factory01",
  "toFactoryId": "Factory02",
  "amount": 100.0
}
```

### Energy Trading with TEC

#### Create a Trade
```bash
POST /api/trade/create
Content-Type: application/json

{
  "tradeId": "TRADE001",
  "sellerId": "Factory01",
  "buyerId": "Factory02",
  "amount": 150.0,
  "pricePerUnit": 0.5
}
```

**Note**: `pricePerUnit` is in TEC tokens per kWh

#### Execute a Trade
```bash
POST /api/trade/execute
Content-Type: application/json

{
  "tradeId": "TRADE001"
}
```

This will:
1. Transfer energy from seller to buyer
2. Execute a real TEC token TransferTransaction on Hedera network (visible on HashScan)
3. Update local database balances
4. Return the Hedera transaction ID for verification

**Important**: The transaction will be visible on the Hedera network explorer:
- Testnet: `https://hashscan.io/testnet/transaction/{transactionId}`
- Mainnet: `https://hashscan.io/mainnet/transaction/{transactionId}`

#### Get Trade Information
```bash
GET /api/trade/TRADE001
```

### Query Endpoints

#### Get Energy Status (Surplus/Deficit)
```bash
GET /api/factory/Factory01/energy-status
```

#### Get Transaction History
```bash
GET /api/factory/Factory01/history
```

#### Update Available Energy
```bash
PUT /api/factory/Factory01/available-energy
Content-Type: application/json

{
  "availableEnergy": 1500.0
}
```

#### Update Daily Consumption
```bash
PUT /api/factory/Factory01/daily-consumption
Content-Type: application/json

{
  "dailyConsumption": 900.0
}
```

## 💡 Usage Examples

### Example 1: Register Factories and Mint Energy

```bash
# Register Factory01 (Solar)
curl -X POST http://localhost:3000/api/factory/register \
  -H "Content-Type: application/json" \
  -d '{
    "factoryId": "Factory01",
    "name": "Solar Plant A",
    "initialBalance": 1000,
    "energyType": "solar",
    "currencyBalance": 1000,
    "dailyConsumption": 800,
    "availableEnergy": 1200
  }'

# Register Factory02 (Wind)
curl -X POST http://localhost:3000/api/factory/register \
  -H "Content-Type: application/json" \
  -d '{
    "factoryId": "Factory02",
    "name": "Wind Farm B",
    "initialBalance": 500,
    "energyType": "wind",
    "currencyBalance": 800,
    "dailyConsumption": 600,
    "availableEnergy": 450
  }'

# Factory01 generates surplus energy
curl -X POST http://localhost:3000/api/energy/mint \
  -H "Content-Type: application/json" \
  -d '{
    "factoryId": "Factory01",
    "amount": 500
  }'
```

### Example 2: Create and Execute Energy Trade

```bash
# Factory01 wants to sell 200 kWh to Factory02 at 0.5 TEC per kWh
curl -X POST http://localhost:3000/api/trade/create \
  -H "Content-Type: application/json" \
  -d '{
    "tradeId": "TRADE_20250101_001",
    "sellerId": "Factory01",
    "buyerId": "Factory02",
    "amount": 200,
    "pricePerUnit": 0.5
  }'

# Execute the trade
curl -X POST http://localhost:3000/api/trade/execute \
  -H "Content-Type: application/json" \
  -d '{
    "tradeId": "TRADE_20250101_001"
  }'

# Check updated balances
curl http://localhost:3000/api/factory/Factory01/balance
# Factory01: energy -200 kWh, currency +100 TEC

curl http://localhost:3000/api/factory/Factory02/balance
# Factory02: energy +200 kWh, currency -100 TEC
```

### Example 3: View Transaction History

```bash
# Get all transactions for Factory01
curl http://localhost:3000/api/factory/Factory01/history

# Response includes:
# - REGISTER: Initial registration
# - MINT: Energy generation
# - TRADE_SELL: Sold energy
# - TRANSFER_OUT: Transferred energy
```

## 🔄 Transformation from Hyperledger to Hedera

This system translates the Hyperledger Fabric energy trading network to Hedera:

### Key Differences

| Feature | Hyperledger Fabric | Hedera Hashgraph |
|---------|-------------------|------------------|
| **Consensus** | Raft/PBFT | Hashgraph Consensus |
| **Smart Contracts** | Chaincode (Go) | HCS + Token Service |
| **Tokens** | Internal ledger | Native HTS tokens |
| **Transaction Speed** | ~1000 TPS | ~10,000 TPS |
| **Finality** | Seconds | 3-5 seconds |
| **Cost** | Free (private) | ~$0.0001 per transaction |

### What Was Transformed

1. **Chaincode → JavaScript SDK**
   - Hyperledger Go chaincode replaced with Hedera SDK calls
   - All functions (mint, transfer, trade) implemented using Hedera APIs

2. **Internal Tokens → TEC Token**
   - Energy tokens now represented as TEC cryptocurrency
   - Native Hedera Token Service (HTS) for token management

3. **Fabric Network → Hedera Testnet**
   - No need for Docker containers or peer nodes
   - Direct connection to Hedera public network

4. **CouchDB → PostgreSQL**
   - Production-grade database for factory records
   - Better performance and scalability
   - ACID compliance with robust transaction handling
   - Hedera network stores immutable transaction proofs

5. **Gateway/Wallet → Hedera Client**
   - Simplified authentication using account ID and private key
   - No certificate management required

### Maintained Features

✓ All API endpoints remain the same
✓ Factory registration and management
✓ Energy minting (surplus generation)
✓ Direct energy transfers
✓ Trade creation and execution
✓ Transaction history
✓ Balance queries

## 🔐 Security Features

- **Hedera Network Security**: Leverages ABFT consensus
- **Token Security**: HTS tokens are cryptographically secure
- **Private Keys**: Never shared, stored only in .env
- **Transaction Signatures**: All transactions are signed
- **Immutable Records**: Cannot alter past transactions
- **Audit Trail**: Complete history on Hedera network

## 📊 How It Works

### 1. Token Economy

```
TEC (Tunisian Energy Coin)
├─ Symbol: TEC
├─ Decimals: 2
├─ Initial Supply: 10,000.00 TEC
├─ Supply Type: Infinite (mintable)
└─ Usage: Payment for energy trades
```

### 2. Energy Trading Flow

```
1. Factory generates surplus energy
   └─ POST /api/energy/mint → Increases energyBalance

2. Seller creates trade offer
   └─ POST /api/trade/create → Creates pending trade

3. Buyer accepts and executes trade
   └─ POST /api/trade/execute
       ├─ Transfer energy: seller → buyer
       ├─ Transfer TEC: buyer → seller
       └─ Record on Hedera (optional)

4. Both parties updated
   ├─ Seller: +TEC, -energy
   └─ Buyer: -TEC, +energy
```

### 3. Data Storage

```
PostgreSQL Database:
├─ factories: Factory profiles and balances
├─ trades: Trade records and status
└─ transaction_history: Complete audit trail

Hedera Network:
├─ TEC token transactions
├─ Topic messages for logging
└─ Consensus timestamps
```

## 🛠️ Development

### Project Structure

```
hedera-energy-trading/
├── server.js              # REST API server
├── hedera-client.js       # Hedera client configuration
├── init-token.js          # TEC token creation script
├── energy-trading.js      # Core trading logic
├── database.js            # SQLite database manager
├── package.json           # Dependencies
├── .env.example           # Environment template
└── README.md              # This file
```

### Database Schema

**factories**
- factoryId (PK)
- name
- hederaAccountId
- energyType
- energyBalance
- currencyBalance (TEC)
- dailyConsumption
- availableEnergy
- createdAt
- updatedAt

**trades**
- tradeId (PK)
- sellerId (FK)
- buyerId (FK)
- amount
- pricePerUnit
- totalPrice
- status
- hederaTransactionId
- timestamp

**transaction_history**
- id (PK)
- factoryId (FK)
- transactionType
- amount
- relatedFactoryId
- hederaTransactionId
- timestamp

## 🌐 Monitoring

### View TEC Token on Hedera

```
https://hashscan.io/testnet/token/{YOUR_TOKEN_ID}
```

### Check Transaction History

```bash
curl http://localhost:3000/api/factory/Factory01/history
```

### View All Factories

```bash
curl http://localhost:3000/api/factories
```

## 🐛 Troubleshooting

### Issue: "connect ECONNREFUSED 127.0.0.1:5432" or "Failed to initialize database"
This error occurs when the server cannot connect to PostgreSQL.

**Solutions**:

1. **Verify PostgreSQL is running**:
   ```bash
   # Ubuntu/Debian
   sudo systemctl status postgresql
   # If not running, start it:
   sudo systemctl start postgresql
   
   # macOS
   brew services list | grep postgresql
   # If not running, start it:
   brew services start postgresql@15
   
   # Windows
   # Check Services app for "postgresql" service
   ```

2. **Check PostgreSQL is listening on port 5432**:
   ```bash
   netstat -an | grep 5432
   # OR
   sudo lsof -i :5432
   ```

3. **Verify database exists**:
   ```bash
   sudo -u postgres psql -l | grep ecoguardians
   # If not listed, create it:
   sudo -u postgres psql -c "CREATE DATABASE ecoguardians;"
   ```

4. **Check credentials in `.env` file**:
   - Ensure `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, and `DB_PASSWORD` are correct
   - Default PostgreSQL user is `postgres` with no password or password `postgres`

5. **Test PostgreSQL connection manually**:
   ```bash
   psql -h localhost -p 5432 -U postgres -d ecoguardians
   # If this fails, check your PostgreSQL authentication settings
   ```

6. **Check PostgreSQL authentication (pg_hba.conf)**:
   - On Ubuntu: `/etc/postgresql/*/main/pg_hba.conf`
   - On macOS: `/usr/local/var/postgresql@15/pg_hba.conf`
   - Ensure local connections are allowed (use `trust` or `md5` for authentication)

### Issue: "Environment variables must be present"
**Solution**: Create `.env` file with your Hedera account credentials and PostgreSQL configuration

### Issue: "Port 3000 already in use"
**Solution**: 
```bash
# Change port in .env
PORT=3001
# Or kill the process using port 3000
```

### Issue: "TEC_TOKEN_ID not configured"
**Solution**: Run `npm run init` to create the token, then add Token ID to `.env`

### Issue: "Factory not found"
**Solution**: Register the factory first using `/api/factory/register`

### Issue: "Insufficient balance"
**Solution**: Check balances with `/api/factory/:id/balance` and ensure sufficient funds

## 📚 Additional Resources

- [Hedera Documentation](https://docs.hedera.com/)
- [Hedera SDK for JavaScript](https://github.com/hashgraph/hedera-sdk-js)
- [Hedera Token Service](https://docs.hedera.com/guides/docs/sdks/tokens)
- [Hashscan Explorer](https://hashscan.io/)

## 📝 License

Apache-2.0

## 🤝 Contributing

This is a demonstration project for industrial energy trading. Future enhancements:

- Integration with Hedera smart contracts (HCS)
- Multi-signature trade approvals
- Automated market making
- Price discovery mechanisms
- Real-time energy monitoring
- Mobile app integration
- Advanced analytics dashboard

## 🎯 Next Steps

1. **Test the system** with multiple factories
2. **Monitor transactions** on Hashscan
3. **Integrate with IoT sensors** for automatic energy readings
4. **Connect mobile app** for factory management
5. **Scale to production** with mainnet deployment

---

**Built with Hedera Hashgraph for sustainable energy trading** ⚡🌱
