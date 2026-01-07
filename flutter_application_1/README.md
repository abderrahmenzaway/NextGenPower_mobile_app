# next gen-power - Flutter Mobile App

A peer-to-peer energy trading platform built with Flutter for industrial factories.

---

## 📱 Screenshots

![Login Screen](screenshots/login_screen.png)
*Login and registration interface*

![Dashboard](screenshots/dashboard.png)
*Main dashboard showing available factories*

![My Factory](screenshots/my_factory.png)
*Factory energy monitoring and statistics*

![Trading Offers](screenshots/trading_offers.png)
*Energy trading marketplace*

![Blockchain Explorer](screenshots/blockchain_screen.png)
*Blockchain transactions and statistics*

![Profile](screenshots/profile_screen.png)
*User profile and settings*

---

## ✨ Features

- **🔐 Authentication** - Secure factory login with password protection
- **📊 Dashboard** - Real-time energy trading opportunities
- **⚡ My Factory** - Monitor energy generation, consumption & battery
- **💱 Trading** - Create and execute energy buy/sell offers
- **⛓️ Blockchain** - View transaction history on Hedera network
- **👤 Profile** - Manage account and preferences

---

## 🚀 Quick Start

See [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md) for complete setup guide.

**Short version:**
```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## 📁 Project Structure

```
lib/
├── main.dart                  # App entry & navigation
├── models/                    # Data models
│   ├── factory.dart
│   ├── trade.dart
│   └── energy_offer.dart
├── providers/                 # State management
│   └── energy_data_provider.dart
├── screens/                   # UI screens
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── my_factory_screen.dart
│   ├── blockchain_screen.dart
│   └── profile_screen.dart
├── services/                  # Backend integration
│   └── api_service.dart
└── widgets/                   # Reusable components
```

---

## 🛠️ Technology Stack

- **Flutter 3.9.2** - Cross-platform framework
- **Provider** - State management
- **FL Chart** - Data visualization
- **HTTP** - API communication
- **Material Design** - UI components

---

## 🔗 API Integration

Backend: `http://localhost:3000` (configurable)

Key endpoints:
- `POST /api/factory/login` - Authentication
- `GET /api/factories` - List factories
- `POST /api/trade/create` - Create trade
- `GET /api/treasury/transactions` - Blockchain data

Configure in `lib/services/api_service.dart`

---

## 📖 Documentation

- **Setup Guide**: [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md)
- **Main Project**: [../README.md](../README.md)
- **Backend API**: [../blockchain/hedera-energy-trading/README.md](../blockchain/hedera-energy-trading/README.md)

