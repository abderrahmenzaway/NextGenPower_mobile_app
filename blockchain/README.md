# EcoGuardians Blockchain Systems

This directory contains blockchain implementations for the EcoGuardians energy management system.

## Available Implementations

### 1. Hedera Energy Trading Network (Recommended) ⭐

**Location**: `/hedera-energy-trading/`

A complete energy trading system built on **Hedera Hashgraph** using the **TEC (Tunisian Energy Coin)** token for peer-to-peer energy transactions.

**Features:**
- ✅ Native cryptocurrency (TEC token)
- ✅ Fast transactions (3-5 seconds)
- ✅ Low cost (~$0.0001 per transaction)
- ✅ Simple setup (5 minutes)
- ✅ Public audit trail
- ✅ High throughput (10,000+ TPS)
- ✅ Complete API for factory management
- ✅ Energy trading with real cryptocurrency

**Quick Start:**
```bash
cd hedera-energy-trading
npm install
npm run init    # Create TEC token
npm start       # Start API server
```

**Documentation:**
- [INDEX.md](./hedera-energy-trading/INDEX.md) - Documentation guide
- [QUICK_START.md](./hedera-energy-trading/QUICK_START.md) - 10-minute setup
- [README.md](./hedera-energy-trading/README.md) - Complete guide
- [HOW_IT_WORKS.md](./hedera-energy-trading/HOW_IT_WORKS.md) - Technical details
- [TRANSFORMATION_SUMMARY.md](./hedera-energy-trading/TRANSFORMATION_SUMMARY.md) - Hyperledger comparison

**Best for:**
- Production deployments
- Real token-based trading
- Public transparency
- Quick setup and deployment
- Minimal infrastructure

---

### 2. Original Hedera Implementation

**Location**: `/files/`

A basic Hedera implementation for renewable energy tokenization using ECoin tokens.

**Features:**
- Basic token creation
- Energy data recording in PostgreSQL
- Simple token transfers
- Server API for energy data submission

**Note**: This is the original reference implementation. For production use, we recommend the **Hedera Energy Trading Network** above, which provides:
- Complete factory management
- Trade creation and execution
- Comprehensive API
- TEC cryptocurrency integration
- Full documentation

---

## System Comparison

| Feature | Hedera Energy Trading | Original Files |
|---------|----------------------|----------------|
| **Token** | TEC (Tunisian Energy Coin) | ECoin |
| **Factory Management** | ✅ Complete | ❌ No |
| **Trade Creation** | ✅ Yes | ❌ No |
| **Trade Execution** | ✅ With TEC payment | ❌ No |
| **REST API** | ✅ Full CRUD | ⚠️ Basic |
| **Database** | ✅ PostgreSQL production-ready | ⚠️ Simple table |
| **Documentation** | ✅ Comprehensive | ⚠️ Basic |
| **Production Ready** | ✅ Yes | ⚠️ Demo only |

## Getting Started

### For New Users

1. Navigate to the Hedera Energy Trading Network:
   ```bash
   cd hedera-energy-trading
   ```

2. Read the documentation guide:
   ```bash
   cat INDEX.md
   ```

3. Follow the quick start:
   ```bash
   cat QUICK_START.md
   ```

### For Existing Hyperledger Users

The original Hyperledger Fabric energy trading network has been replaced with Hedera Hashgraph.

1. Read the transformation summary:
   ```bash
   cd hedera-energy-trading
   cat TRANSFORMATION_SUMMARY.md
   ```

2. The new system maintains **100% API compatibility** with the original endpoints
3. Setup is **much simpler** (no Docker, no complex network configuration)
4. All features are preserved and enhanced

## Architecture Overview

### Hedera Energy Trading Network Architecture

```
┌──────────────────────────────────────────┐
│         Industrial Zone                   │
│  Multiple Factories                       │
│  (Solar/Wind/Footstep Energy)            │
└──────────────┬───────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│        REST API Server                    │
│        (Express.js)                       │
│  - Factory registration                   │
│  - Energy minting                         │
│  - Trade creation/execution               │
│  - Balance queries                        │
└──────────────┬───────────────────────────┘
               │
       ┌───────┴────────┐
       │                │
       ▼                ▼
┌─────────────┐  ┌─────────────────────────┐
│  PostgreSQL │  │   Hedera Hashgraph      │
│  Database   │  │   Network (Cloud)       │
│             │  │                         │
│ - Factories │  │ - TEC Token (HTS)       │
│ - Trades    │  │ - Consensus Service     │
│ - History   │  │ - Public Ledger         │
└─────────────┘  └─────────────────────────┘
```

## Use Cases

### Industrial Energy Trading
- Factories trade surplus renewable energy
- Peer-to-peer energy marketplace
- Reduce energy costs through trading
- Maximize renewable energy utilization

### Microgrid Management
- Community energy sharing
- Local energy markets
- Building-to-building trading
- Smart grid integration

### IoT Integration
- Automated energy readings
- Smart contract execution
- Real-time pricing
- Demand response

## Technology Stack

### Hedera Energy Trading Network

**Blockchain**: Hedera Hashgraph (Testnet/Mainnet)
**Token**: TEC (Tunisian Energy Coin) via Hedera Token Service
**Backend**: Node.js + Express.js
**Database**: PostgreSQL
**SDK**: @hashgraph/sdk
**API**: RESTful HTTP/JSON

**Dependencies**:
- @hashgraph/sdk: ^2.54.2
- express: ^4.21.1
- pg: ^8.13.1
- dotenv: ^16.4.5
- body-parser: ^1.20.2
- cors: ^2.8.5

## API Endpoints

### Factory Management
- `POST /api/factory/register` - Register new factory
- `GET /api/factory/:id` - Get factory details
- `GET /api/factories` - List all factories
- `GET /api/factory/:id/balance` - Get balances (energy + TEC)
- `GET /api/factory/:id/energy-status` - Get energy status

### Energy Operations
- `POST /api/energy/mint` - Generate energy tokens
- `POST /api/energy/transfer` - Direct energy transfer
- `PUT /api/factory/:id/available-energy` - Update available energy
- `PUT /api/factory/:id/daily-consumption` - Update consumption

### Trading
- `POST /api/trade/create` - Create energy trade
- `POST /api/trade/execute` - Execute trade (with TEC payment)
- `GET /api/trade/:id` - Get trade details

### History
- `GET /api/factory/:id/history` - Transaction history

## Environment Setup

### Prerequisites

1. **Node.js** v16+ and npm
2. **PostgreSQL** v12+ database server
3. **Hedera Testnet Account**
   - Create at: https://portal.hedera.com/
   - Get Account ID and Private Key

### Configuration

Create `.env` file:
```env
MY_ACCOUNT_ID=0.0.XXXXXXX
MY_PRIVATE_KEY=your_private_key_here
TREASURY_ACCOUNT_ID=0.0.XXXXXXX
TEC_TOKEN_ID=           # Generated during setup
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=ecoguardians
DB_USER=postgres
DB_PASSWORD=postgres
```

### Database Setup

Create the PostgreSQL database and tables:

```bash
# Create database
createdb ecoguardians

# Run schema
psql -d ecoguardians -f hedera-energy-trading/schema.sql
```

## Security Considerations

- ✅ Private keys stored in `.env` (not committed)
- ✅ Transaction signing via Hedera SDK
- ✅ Input validation on all endpoints
- ✅ Balance checks before transfers
- ✅ Trade atomicity (all-or-nothing)
- ✅ Immutable audit trail on Hedera

## Performance

- **Transaction Speed**: 3-5 seconds
- **Throughput**: 10,000+ TPS (Hedera network)
- **Cost**: ~$0.0001 per transaction
- **Scalability**: Horizontal (add more factories)
- **Availability**: 99.99% (Hedera network)

## Monitoring

### Hedera Explorer
View tokens and transactions:
```
https://hashscan.io/testnet/token/{YOUR_TOKEN_ID}
```

### API Health Check
```bash
curl http://localhost:3000/api/health
```

### Database Query
```bash
psql -d ecoguardians -c "SELECT * FROM factories;"
```

## Contributing

To add features or improvements:

1. Clone the repository
2. Navigate to `blockchain/hedera-energy-trading/`
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Related Systems

### Energy Trading Network (Hyperledger Fabric)

The original implementation using Hyperledger Fabric has been replaced with Hedera Hashgraph.

**Key Differences**:
- Hyperledger: Private network, Docker-based, complex setup
- Hedera: Public network, cloud-based, simple setup
- Both: Same API endpoints, same functionality

See [TRANSFORMATION_SUMMARY.md](./hedera-energy-trading/TRANSFORMATION_SUMMARY.md) for detailed comparison.

## Support & Resources

- **Documentation**: See `hedera-energy-trading/INDEX.md`
- **Quick Start**: See `hedera-energy-trading/QUICK_START.md`
- **Hedera Docs**: https://docs.hedera.com/
- **Hedera Portal**: https://portal.hedera.com/
- **Hedera SDK**: https://github.com/hashgraph/hedera-sdk-js

## License

Apache-2.0

## Acknowledgments

This system demonstrates sustainable energy trading using blockchain technology, enabling factories to maximize renewable energy usage through peer-to-peer trading with cryptocurrency incentives.

---

**Built with Hedera Hashgraph for sustainable energy trading** ⚡🌱
