# System Architecture - Updated Trading Platform

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     EcoGuardians Trading Platform                │
│                      Professional Energy Trading                  │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐         ┌──────────────────┐         ┌──────────────────┐
│   Flutter App    │────────▶│   REST API       │────────▶│  Hedera Network  │
│  (Mobile/Web)    │  HTTPS  │  (Node.js)       │   SDK   │   (Blockchain)   │
└──────────────────┘         └──────────────────┘         └──────────────────┘
         │                            │                             │
         │                            │                             │
         ▼                            ▼                             ▼
┌──────────────────┐         ┌──────────────────┐         ┌──────────────────┐
│  User Interface  │         │PostgreSQL Database│         │   TEC Token      │
│  Screens/Widgets │         │  Persistent Data  │         │   Testnet Acct   │
└──────────────────┘         └──────────────────┘         └──────────────────┘
```

## Authentication Flow

### Before Update (Insecure)
```
User enters Factory ID ──▶ Direct access to dashboard
                          No validation
                          No security
```

### After Update (Secure)
```
┌─────────────────────────────────────────────────────────────────┐
│ Registration Flow                                                 │
└─────────────────────────────────────────────────────────────────┘

User Input                    Backend Processing              Blockchain
───────────                   ──────────────────              ──────────
Factory ID                    
Factory Name               ┌─▶ Hash password (bcrypt)
Password          ────────▶│   Store in database         ┌─▶ Create Hedera Account
Confirm Password           │   Generate unique ID        │   Associate TEC token
Initial Balances           └─▶ Call Hedera API  ─────────┘   Transfer initial TEC
Energy Type                    Return account info              Return account ID
                               Send to Flutter app              Store in database

┌─────────────────────────────────────────────────────────────────┐
│ Login Flow                                                        │
└─────────────────────────────────────────────────────────────────┘

User Input                    Backend Processing              Response
───────────                   ──────────────────              ────────
Factory ID        ────────▶   Query database           ┌─▶ Factory data
Password                      Compare with hash        │   Hedera account ID
                              bcrypt.compare()   ──────┘   TEC balance
                              Validate match                Energy stats
                                                             ✓ or ✗
```

## Data Flow

### Profile Screen Data
```
Profile Screen ──▶ API Request ──▶ Database Query ──▶ Response
     │                                    │                │
     │                                    ▼                │
     │                            ┌──────────────┐        │
     └────────────────────────────│ Factory Data │◀───────┘
                                  │ - ID, Name   │
                                  │ - Hedera ID  │
                                  │ - TEC Balance│
                                  │ - Energy Data│
                                  └──────────────┘
```

### Trading Flow
```
┌──────────────────────────────────────────────────────────────────┐
│ User Creates Offer                                                │
└──────────────────────────────────────────────────────────────────┘

User Action                   API Processing                Blockchain
───────────                   ──────────────                ──────────
Select Offer Type          ┌─▶ Generate Trade ID
Enter Amount      ────────▶│   Validate parameters      ┌─▶ Create trade record
Enter Price                │   Store in database        │   (pending status)
Click Create               └─▶ Call Hedera API ─────────┘   Log to HCS topic
                               Update UI                      Return transaction ID

┌──────────────────────────────────────────────────────────────────┐
│ User Executes Trade                                               │
└──────────────────────────────────────────────────────────────────┘

User Action                   API Processing                Blockchain
───────────                   ──────────────                ──────────
Browse Offers              ┌─▶ Validate balances       ┌─▶ Transfer energy tokens
Click Accept      ────────▶│   Check permissions        │   Transfer TEC tokens
Confirm Trade              │   Update database          │   Update balances
                           └─▶ Execute on Hedera ───────┘   Log to HCS topic
                               Return confirmation            Return receipts
```

## Database Schema

### Factories Table (Updated)
```
┌────────────────────────────────────────────────────────────┐
│ factories                                                   │
├────────────────────────────────────────────────────────────┤
│ factoryId          TEXT PRIMARY KEY                        │
│ name               TEXT NOT NULL                           │
│ passwordHash       TEXT NOT NULL          ◀── NEW FIELD    │
│ hederaAccountId    TEXT                                    │
│ hederaPrivateKey   TEXT (encrypted)                        │
│ energyType         TEXT NOT NULL                           │
│ energyBalance      REAL DEFAULT 0                          │
│ currencyBalance    REAL DEFAULT 0         ◀── TEC Balance  │
│ dailyConsumption   REAL DEFAULT 0                          │
│ availableEnergy    REAL DEFAULT 0                          │
│ createdAt          INTEGER                                 │
│ updatedAt          INTEGER                                 │
└────────────────────────────────────────────────────────────┘
```

### Trades Table
```
┌────────────────────────────────────────────────────────────┐
│ trades                                                      │
├────────────────────────────────────────────────────────────┤
│ tradeId              TEXT PRIMARY KEY                      │
│ sellerId             TEXT NOT NULL (FK)                    │
│ buyerId              TEXT NOT NULL (FK)                    │
│ amount               REAL NOT NULL                         │
│ pricePerUnit         REAL NOT NULL                         │
│ totalPrice           REAL NOT NULL                         │
│ status               TEXT DEFAULT 'pending'                │
│ hederaTransactionId  TEXT                                  │
│ timestamp            INTEGER                               │
└────────────────────────────────────────────────────────────┘
```

## Screen Navigation

```
Login Screen
    │
    ├─▶ Register ──▶ Create Account ──▶ Dashboard
    │
    └─▶ Login ────▶ Authenticate ────▶ Dashboard
                                           │
                    ┌──────────────────────┼──────────────────────┐
                    │                      │                      │
                    ▼                      ▼                      ▼
              My Factory              Trading Offers         Dashboard
              (Energy Data)           (Create/Execute)       (Overview)
                    │                      │                      │
                    │                      │                      │
                    └─────────┬────────────┴──────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    ▼                   ▼
              Profile Screen      Blockchain Screen
              (Account Info)      (Token Balance)
              (Hedera ID)         (Hedera ID)
```

## Security Layers

```
┌─────────────────────────────────────────────────────────────────┐
│ Layer 1: User Authentication                                     │
│ - Password required for all operations                           │
│ - bcrypt hashing (10 rounds)                                     │
│ - Session management                                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Layer 2: API Security                                            │
│ - Input validation                                               │
│ - SQL injection prevention                                       │
│ - Request rate limiting (future)                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Layer 3: Database Security                                       │
│ - Hashed passwords only                                          │
│ - Encrypted private keys                                         │
│ - Parameterized queries                                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Layer 4: Blockchain Security                                     │
│ - Hedera Hashgraph consensus                                     │
│ - Immutable transaction records                                  │
│ - Token association required                                     │
└─────────────────────────────────────────────────────────────────┘
```

## Component Interaction

### Registration Process
```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│ Flutter  │────▶│  Server  │────▶│ Database │     │  Hedera  │
│   App    │     │  (API)   │     │PostgreSQL│     │ Network  │
└──────────┘     └──────────┘     └──────────┘     └──────────┘
     │                │                 │                 │
     │ 1. Register    │                 │                 │
     │ ──────────────▶│                 │                 │
     │                │ 2. Hash pwd     │                 │
     │                │ ──────────────▶ │                 │
     │                │ 3. Store        │                 │
     │                │ ──────────────▶ │                 │
     │                │ 4. Create acct  │                 │
     │                │ ────────────────────────────────▶ │
     │                │                 │ 5. Account ID   │
     │                │ ◀──────────────────────────────── │
     │                │ 6. Save ID      │                 │
     │                │ ──────────────▶ │                 │
     │ 7. Success     │                 │                 │
     │ ◀────────────── │                 │                 │
     │                │                 │                 │
```

### Trading Process
```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│ Factory A│────▶│  Server  │────▶│ Database │     │  Hedera  │
│  (Seller)│     │  (API)   │     │PostgreSQL│     │ Network  │
└──────────┘     └──────────┘     └──────────┘     └──────────┘
     │                │                 │                 │
┌──────────┐          │                 │                 │
│ Factory B│          │                 │                 │
│  (Buyer) │          │                 │                 │
└──────────┘          │                 │                 │
     │                │                 │                 │
     │ 1. Create offer│                 │                 │
     │ ──────────────▶│                 │                 │
     │                │ 2. Store        │                 │
     │                │ ──────────────▶ │                 │
     │ 3. Browse      │                 │                 │
     │ ──────────────▶│                 │                 │
     │ 4. Accept      │                 │                 │
     │ ──────────────▶│                 │                 │
     │                │ 5. Execute      │                 │
     │                │ ────────────────────────────────▶ │
     │                │                 │ 6. Transfer     │
     │                │                 │    tokens       │
     │                │ ◀──────────────────────────────── │
     │                │ 7. Update DB    │                 │
     │                │ ──────────────▶ │                 │
     │ 8. Confirm     │                 │                 │
     │ ◀────────────── │                 │                 │
     │                │                 │                 │
```

## Key Improvements

- ✅ Secure password authentication
- ✅ Real blockchain integration
- ✅ User-controlled trading
- ✅ Professional UI/UX
- ✅ Comprehensive documentation
