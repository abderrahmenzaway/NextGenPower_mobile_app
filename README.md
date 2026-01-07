# EcoGuardians - Industrial Energy Trading & Monitoring Platform

A comprehensive **Hedera Hashgraph** blockchain-based energy trading system with AI-powered monitoring for industrial zones.

---

## 📸 Screenshots

![System Architecture](screenshots/image.png)
*Overall system architecture and components*

![Mobile App - Dashboard](screenshots/7954.jpg)
*Mobile app dashboard showing energy trading*

![Blockchain Transactions](screenshots/7948.jpg)
*Hedera blockchain transaction explorer*

![Energy Monitoring](screenshots/7952.jpg)
*Real-time energy monitoring dashboard*

---

## 🌟 Overview

EcoGuardians combines blockchain, AI, and IoT for complete industrial energy management:

- **⛓️ Blockchain Trading** - Hedera Hashgraph with TEC token
- **🤖 AI Monitoring** - Energy disaggregation & demand forecasting
- **📱 Mobile App** - Flutter-based factory management
- **🔌 IoT Integration** - Arduino sensor interfaces

---

## 📁 Project Structure

```
EcoGuardians-main/
├── flutter_application_1/         # 📱 Mobile app (next gen-power)
├── blockchain/
│   ├── hedera-energy-trading/    # ⛓️ Trading platform (Node.js + PostgreSQL)
│   └── files/                    # Energy data recording
├── AI-models/
│   ├── Desagrigation-model/      # 🤖 NILM energy disaggregation
│   └── Failure-detection/        # ⚠️ Equipment failure detection
```

---

## 🚀 Quick Start (3 Steps)

### 1. Setup Database
```bash
# Install PostgreSQL
sudo apt install postgresql

# Create database
sudo -u postgres psql
CREATE DATABASE ecoguardians;
\q
```

### 2. Start Backend
```bash
cd blockchain/hedera-energy-trading
npm install
cp .env.example .env
# Edit .env with your credentials
npm start
```

### 3. Run Mobile App
```bash
cd flutter_application_1
flutter pub get
flutter run
```

---

## 📱 Mobile App Features

- ✅ Factory authentication & registration
- ✅ Real-time energy monitoring
- ✅ P2P energy trading marketplace
- ✅ Blockchain transaction history
- ✅ Profile & settings management

See [flutter_application_1/README.md](flutter_application_1/README.md) for details.

---

## 🔑 Key Technologies

| Component | Technology |
|-----------|------------|
| Blockchain | Hedera Hashgraph |
| Token | TEC (Tunisian Energy Coin) |
| Backend | Node.js, Express |
| Database | PostgreSQL |
| Mobile | Flutter (Dart) |
| AI/ML | Python, TensorFlow |
| IoT | Arduino |

---

## 📚 API Endpoints

### Authentication
- `POST /api/factory/register` - Register factory
- `POST /api/factory/login` - Login

### Energy Trading
- `POST /api/energy/mint` - Mint energy tokens
- `POST /api/trade/create` - Create trade
- `POST /api/trade/execute` - Execute trade

### Queries
- `GET /api/factories` - List all factories
- `GET /api/factory/:id/balance` - Get balance
- `GET /api/treasury/transactions` - Blockchain history

Full API docs: [blockchain/hedera-energy-trading/README.md](blockchain/hedera-energy-trading/README.md)

---

## 🔧 Configuration

**Environment Variables** (`.env`):
```env
# Hedera Credentials
MY_ACCOUNT_ID=0.0.XXXXXXX
MY_PRIVATE_KEY=302e...
TEC_TOKEN_ID=0.0.XXXXXXX

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=ecoguardians
DB_USER=postgres
DB_PASSWORD=your_password

# Server
PORT=3000
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| PostgreSQL connection failed | Check `sudo systemctl status postgresql` |
| TEC token not found | Run `npm run init` in backend |
| bcrypt error (Windows) | Use WSL to run backend |
| Flutter build fails | Run `flutter doctor --android-licenses` |
| App can't connect | Verify backend is running on port 3000 |

---

## 📊 Monitoring

**View on Hedera Network:**
- Testnet: `https://hashscan.io/testnet/transaction/{txId}`
- Token: `https://hashscan.io/testnet/token/{TEC_TOKEN_ID}`

---

## 🎯 Setup Checklist

- [ ] Install PostgreSQL & create database
- [ ] Install Node.js & dependencies  
- [ ] Create Hedera testnet account
- [ ] Configure `.env` file
- [ ] Initialize TEC token
- [ ] Start backend server
- [ ] Install Flutter SDK
- [ ] Run mobile app
- [ ] Register first factory
- [ ] Execute first trade

---

## 📖 Documentation

- **[flutter_application_1/BUILD_INSTRUCTIONS.md](flutter_application_1/BUILD_INSTRUCTIONS.md)** - Mobile app setup
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture
- **[blockchain/hedera-energy-trading/README.md](blockchain/hedera-energy-trading/README.md)** - Backend API docs

---

## 🤝 Contributing

Future enhancements:
- Multi-region trading
- Carbon credit integration  
- Advanced market algorithms
- Real-time IoT streaming
- Enhanced AI models

---

## 📝 License

Apache-2.0

---

**Built with Hedera Hashgraph for sustainable energy trading** ⚡🌱
