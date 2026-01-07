# Quick Start Guide - Hedera Energy Trading

This guide will help you get the Hedera energy trading system up and running in 10 minutes.

## Prerequisites Checklist

- [ ] Node.js v16+ installed
- [ ] Hedera Testnet account created
- [ ] Account ID and Private Key saved

## Step-by-Step Setup

### 1. Install Dependencies (2 minutes)

```bash
cd blockchain/hedera-energy-trading
npm install
```

Wait for all packages to install...

### 2. Configure Environment (1 minute)

Create `.env` file:

```bash
cp .env.example .env
```

Edit `.env` with your credentials:

```env
MY_ACCOUNT_ID=0.0.YOUR_ACCOUNT_ID
MY_PRIVATE_KEY=your_private_key_here
TREASURY_ACCOUNT_ID=0.0.YOUR_ACCOUNT_ID
TEC_TOKEN_ID=
PORT=3000
```

### 3. Create TEC Token (2 minutes)

```bash
npm run init
```

Expected output:
```
========================================
  TEC Token Creation
========================================

Creating TEC token...
✓ TEC Token created successfully!
  Token ID: 0.0.1234567
  Token Name: Tunisian Energy Coin
  Token Symbol: TEC
  Decimals: 2
  Initial Supply: 10,000.00 TEC

========================================
IMPORTANT: Add this to your .env file:
TEC_TOKEN_ID=0.0.1234567
========================================

Explorer Link:
https://hashscan.io/testnet/token/0.0.1234567
```

**Action Required:** Copy the Token ID and add it to your `.env` file:

```env
TEC_TOKEN_ID=0.0.1234567
```

### 4. Start API Server (1 minute)

```bash
npm start
```

Expected output:
```
========================================
   Hedera Energy Trading Network API
========================================
Server running on http://localhost:3000

Blockchain: Hedera Hashgraph
Token: TEC (Tunisian Energy Coin)

Available endpoints:
  GET  /api/health
  POST /api/factory/register
  ...
========================================
✓ Database initialized
```

Server is now running! Keep this terminal open.

### 5. Test the System (4 minutes)

Open a new terminal and run these commands:

#### 5.1 Check API Health

```bash
curl http://localhost:3000/api/health
```

Expected response:
```json
{
  "status": "OK",
  "message": "Hedera Energy Trading API is running",
  "blockchain": "Hedera Hashgraph",
  "token": "TEC (Tunisian Energy Coin)"
}
```

#### 5.2 Register Factory 1 (Solar Plant)

```bash
curl -X POST http://localhost:3000/api/factory/register \
  -H "Content-Type: application/json" \
  -d '{
    "factoryId": "Factory01",
    "name": "Solar Power Plant Alpha",
    "initialBalance": 1000,
    "energyType": "solar",
    "currencyBalance": 1000,
    "dailyConsumption": 800,
    "availableEnergy": 1200
  }'
```

Expected response:
```json
{
  "success": true,
  "message": "Factory Factory01 registered successfully on Hedera network",
  "data": {
    "factoryId": "Factory01",
    "name": "Solar Power Plant Alpha",
    "hederaAccountId": "0.0.XXXXXXX",
    "energyBalance": 1000,
    "energyType": "solar",
    "currencyBalance": 1000
  }
}
```

**Note:** A new Hedera account has been created for Factory01! The account:
- Has been funded with 10 HBAR for transaction fees
- Is associated with the TEC token
- Can now send and receive TEC tokens on the Hedera network

#### 5.3 Register Factory 2 (Wind Farm)

```bash
curl -X POST http://localhost:3000/api/factory/register \
  -H "Content-Type: application/json" \
  -d '{
    "factoryId": "Factory02",
    "name": "Wind Energy Farm Beta",
    "initialBalance": 500,
    "energyType": "wind",
    "currencyBalance": 800,
    "dailyConsumption": 600,
    "availableEnergy": 450
  }'
```

#### 5.4 View All Factories

```bash
curl http://localhost:3000/api/factories
```

Expected response:
```json
{
  "success": true,
  "count": 2,
  "data": [
    {
      "factoryId": "Factory01",
      "name": "Solar Power Plant Alpha",
      "energyBalance": 1000,
      "currencyBalance": 1000,
      ...
    },
    {
      "factoryId": "Factory02",
      "name": "Wind Energy Farm Beta",
      "energyBalance": 500,
      "currencyBalance": 800,
      ...
    }
  ]
}
```

#### 5.5 Mint Energy (Factory01 Generates Surplus)

```bash
curl -X POST http://localhost:3000/api/energy/mint \
  -H "Content-Type: application/json" \
  -d '{
    "factoryId": "Factory01",
    "amount": 500
  }'
```

Expected response:
```json
{
  "success": true,
  "message": "Minted 500 kWh of energy tokens for Factory01",
  "data": {
    "factoryId": "Factory01",
    "previousBalance": 1000,
    "newBalance": 1500,
    "minted": 500
  }
}
```

#### 5.6 Check Updated Balance

```bash
curl http://localhost:3000/api/factory/Factory01/balance
```

Expected response:
```json
{
  "success": true,
  "data": {
    "factoryId": "Factory01",
    "energyBalance": 1500,
    "currencyBalance": 1000
  }
}
```

#### 5.7 Create Energy Trade

Factory01 wants to sell 300 kWh to Factory02 at 0.5 TEC per kWh:

```bash
curl -X POST http://localhost:3000/api/trade/create \
  -H "Content-Type: application/json" \
  -d '{
    "tradeId": "TRADE_DEMO_001",
    "sellerId": "Factory01",
    "buyerId": "Factory02",
    "amount": 300,
    "pricePerUnit": 0.5
  }'
```

Expected response:
```json
{
  "success": true,
  "message": "Trade TRADE_DEMO_001 created successfully (payment in TEC)",
  "data": {
    "tradeId": "TRADE_DEMO_001",
    "sellerId": "Factory01",
    "buyerId": "Factory02",
    "amount": 300,
    "pricePerUnit": 0.5,
    "totalPrice": 150,
    "status": "pending"
  }
}
```

#### 5.8 Execute the Trade

```bash
curl -X POST http://localhost:3000/api/trade/execute \
  -H "Content-Type: application/json" \
  -d '{
    "tradeId": "TRADE_DEMO_001"
  }'
```

Expected response:
```json
{
  "success": true,
  "message": "Trade TRADE_DEMO_001 executed successfully with TEC payment",
  "data": {
    "tradeId": "TRADE_DEMO_001",
    "status": "completed",
    "hederaTransactionId": "0.0.XXXXX@1234567890.123456789"
  }
}
```

**🎉 Success!** You've just executed a real energy trade on Hedera!

**What just happened:**
1. ✅ 150 TEC tokens were transferred from Factory02 to Factory01 on Hedera
2. ✅ 300 kWh of energy was transferred from Factory01 to Factory02
3. ✅ The transaction is permanently recorded on Hedera blockchain
4. ✅ You can view the transaction on HashScan explorer

**View on Explorer:**
Copy the `hederaTransactionId` and visit:
```
https://hashscan.io/testnet/transaction/{hederaTransactionId}
```

You'll see:
- Token transfer details
- Sender and receiver accounts
- Transaction timestamp
- Transaction fee
- Complete transaction history

#### 5.9 Verify Final Balances

Check Factory01 (Seller):
```bash
curl http://localhost:3000/api/factory/Factory01/balance
```

Expected:
```json
{
  "success": true,
  "data": {
    "factoryId": "Factory01",
    "energyBalance": 1200,    // 1500 - 300
    "currencyBalance": 1150   // 1000 + 150
  }
}
```

Check Factory02 (Buyer):
```bash
curl http://localhost:3000/api/factory/Factory02/balance
```

Expected:
```json
{
  "success": true,
  "data": {
    "factoryId": "Factory02",
    "energyBalance": 800,    // 500 + 300
    "currencyBalance": 650   // 800 - 150
  }
}
```

#### 5.10 View Transaction History

```bash
curl http://localhost:3000/api/factory/Factory01/history
```

Expected response shows all transactions:
```json
{
  "success": true,
  "data": [
    {
      "transactionType": "REGISTER",
      "amount": 1000,
      "timestamp": 1704067200
    },
    {
      "transactionType": "MINT",
      "amount": 500,
      "timestamp": 1704067300
    },
    {
      "transactionType": "TRADE_SELL",
      "amount": 300,
      "relatedFactoryId": "Factory02",
      "timestamp": 1704067400
    }
  ]
}
```

## Success! 🎉

You now have a fully functional Hedera-based energy trading system!

## What Just Happened?

1. ✓ Created TEC token on Hedera Hashgraph
2. ✓ Registered two factories in the system
3. ✓ Minted 500 kWh of energy tokens
4. ✓ Created and executed a trade
5. ✓ Transferred energy and TEC tokens
6. ✓ Recorded complete transaction history

## Next Steps

### Explore More Features

1. **Check Energy Status:**
```bash
curl http://localhost:3000/api/factory/Factory01/energy-status
```

2. **Update Available Energy:**
```bash
curl -X PUT http://localhost:3000/api/factory/Factory01/available-energy \
  -H "Content-Type: application/json" \
  -d '{"availableEnergy": 1500}'
```

3. **Direct Energy Transfer:**
```bash
curl -X POST http://localhost:3000/api/energy/transfer \
  -H "Content-Type: application/json" \
  -d '{
    "fromFactoryId": "Factory01",
    "toFactoryId": "Factory02",
    "amount": 100
  }'
```

4. **Get Trade Details:**
```bash
curl http://localhost:3000/api/trade/TRADE_DEMO_001
```

### View on Hedera Explorer

Visit the Hedera explorer to see your TEC token:

```
https://hashscan.io/testnet/token/YOUR_TOKEN_ID
```

Replace `YOUR_TOKEN_ID` with your actual token ID from `.env`.

### Register More Factories

Try adding more factories to simulate a larger industrial zone:

```bash
# Factory 3 - Footstep Power
curl -X POST http://localhost:3000/api/factory/register \
  -H "Content-Type: application/json" \
  -d '{
    "factoryId": "Factory03",
    "name": "Kinetic Energy Facility",
    "initialBalance": 200,
    "energyType": "footstep",
    "currencyBalance": 500,
    "dailyConsumption": 300,
    "availableEnergy": 250
  }'

# Factory 4 - Large Solar Array
curl -X POST http://localhost:3000/api/factory/register \
  -H "Content-Type: application/json" \
  -d '{
    "factoryId": "Factory04",
    "name": "Mega Solar Complex",
    "initialBalance": 2000,
    "energyType": "solar",
    "currencyBalance": 1500,
    "dailyConsumption": 1800,
    "availableEnergy": 2200
  }'
```

### Test Multiple Trades

Create a complex trading scenario:

```bash
# Trade 1: Factory01 → Factory03
curl -X POST http://localhost:3000/api/trade/create \
  -H "Content-Type: application/json" \
  -d '{
    "tradeId": "TRADE002",
    "sellerId": "Factory01",
    "buyerId": "Factory03",
    "amount": 150,
    "pricePerUnit": 0.6
  }'

curl -X POST http://localhost:3000/api/trade/execute \
  -H "Content-Type: application/json" \
  -d '{"tradeId": "TRADE002"}'

# Trade 2: Factory04 → Factory02
curl -X POST http://localhost:3000/api/trade/create \
  -H "Content-Type: application/json" \
  -d '{
    "tradeId": "TRADE003",
    "sellerId": "Factory04",
    "buyerId": "Factory02",
    "amount": 400,
    "pricePerUnit": 0.45
  }'

curl -X POST http://localhost:3000/api/trade/execute \
  -H "Content-Type: application/json" \
  -d '{"tradeId": "TRADE003"}'
```

## Troubleshooting

### Issue: Token creation fails

**Error:** "INSUFFICIENT_TX_FEE"

**Solution:** Your Hedera testnet account needs HBAR for transaction fees. Visit the [Hedera portal](https://portal.hedera.com/) to add testnet HBAR.

### Issue: Port 3000 in use

**Error:** "Port 3000 already in use"

**Solution:** Change the port in `.env`:
```env
PORT=3001
```

Then restart the server.

### Issue: Factory not found

**Error:** "Factory Factory01 not found"

**Solution:** Make sure you registered the factory first using `/api/factory/register`.

### Issue: Insufficient balance

**Error:** "Insufficient energy balance"

**Solution:** 
1. Check current balance: `curl http://localhost:3000/api/factory/Factory01/balance`
2. Mint more energy if needed: `POST /api/energy/mint`

## Learning Resources

- Read `README.md` for complete documentation
- Read `HOW_IT_WORKS.md` for detailed explanation
- Check [Hedera Documentation](https://docs.hedera.com/)
- Explore [Hashscan Explorer](https://hashscan.io/)

## Support

If you encounter issues:

1. Check the server logs in the terminal
2. Verify `.env` configuration
3. Ensure Hedera testnet is accessible
4. Review error messages in API responses

---

**Congratulations!** You've successfully set up a blockchain-based energy trading system using Hedera Hashgraph! 🎉⚡
