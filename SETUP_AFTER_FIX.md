# Quick Setup Guide - After Applying Fixes

This guide helps you get the EcoGuardians application running with all the fixes applied.

## 📋 Prerequisites

Make sure you have:
- ✅ PostgreSQL installed and running
- ✅ Node.js v16+ installed
- ✅ Hedera testnet account (from https://portal.hedera.com)
- ✅ Flutter SDK (if using the mobile app)

## 🚀 Quick Start (5 Steps)

### Step 1: Setup PostgreSQL Database

```bash
# Start PostgreSQL service
sudo systemctl start postgresql  # Linux
brew services start postgresql@15  # macOS

# Create database
sudo -u postgres psql -c "CREATE DATABASE ecoguardians;"

# Verify
sudo -u postgres psql -c "\l" | grep ecoguardians
```

### Step 2: Configure Backend

```bash
cd blockchain/hedera-energy-trading

# Install dependencies
npm install

# Create .env file from example
cp .env.example .env

# Edit .env and add your credentials:
# - MY_ACCOUNT_ID=0.0.YOUR_ACCOUNT_ID
# - MY_PRIVATE_KEY=your_private_key
# - TEC_TOKEN_ID= (leave empty for now)
# - DB_HOST=localhost
# - DB_PORT=5432
# - DB_NAME=ecoguardians
# - DB_USER=postgres
# - DB_PASSWORD=postgres
nano .env
```

### Step 3: Initialize TEC Token

```bash
# Run token initialization (only needed once)
npm run init

# Copy the token ID from output
# It will look like: 0.0.12345678

# Add it to .env file
echo "TEC_TOKEN_ID=0.0.12345678" >> .env
# (Replace 0.0.12345678 with your actual token ID)
```

### Step 4: Start Backend Server

```bash
npm start

# Should see:
# ========================================
#    Hedera Energy Trading Network API
# ========================================
# Server running on http://localhost:3000
# ...
# ✓ Database initialized

# Test it works:
curl http://localhost:3000/api/health
curl http://localhost:3000/api/config
```

### Step 5: Run Flutter App

```bash
cd ../../flutter_application_1

# Install dependencies
flutter pub get

# Run on emulator/device
flutter run

# Or for web
flutter run -d chrome
```

## ✅ Verify Everything Works

### Test 1: Register New Factory

1. Open the Flutter app
2. Click "Register Factory" tab
3. Fill in details:
   - **Factory ID**: TEST-001
   - **Factory Name**: Test Factory
   - **Initial Energy Balance**: 1000
   - **Initial TEC Balance**: 500
   - **Energy Type**: Solar
   - **Password**: test123
   - **Confirm Password**: test123
4. Click "Register Factory"
5. Should see success message
6. Should auto-login to dashboard

### Test 2: Check Profile Screen

1. Navigate to profile (tap profile icon or button)
2. Should see:
   - ✅ **Factory Name**: Test Factory
   - ✅ **Factory ID**: TEST-001
   - ✅ **Hedera Account ID**: 0.0.XXXXXXX (blue box)
   - ✅ **TEC Token ID**: 0.0.XXXXXXX (purple box)
   - ✅ **Currency Balance**: 500.00 TEC (not 0.00!)
   - ✅ **Available Energy**: 1000.0 kWh
   - ✅ **Daily Consumption**: 0.0 kWh

### Test 3: Refresh Functionality

1. Pull down on profile screen
2. Should see loading indicator
3. Data should refresh
4. Or tap refresh button (↻) in top right
5. Should also refresh

### Test 4: Login After Sign Out

1. Scroll to bottom of profile
2. Tap "Sign Out" (red button)
3. Should return to login screen
4. Enter:
   - **Factory ID**: TEST-001
   - **Password**: test123
5. Tap "Login to Dashboard"
6. Should successfully login
7. Navigate to profile again
8. All data should still be there!

## 🔧 Troubleshooting

### Issue: Backend won't start

**Solution:**
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Start if needed
sudo systemctl start postgresql

# Test connection
psql -h localhost -U postgres -d ecoguardians -c "SELECT 1;"
```

### Issue: "TEC_TOKEN_ID not found"

**Solution:**
```bash
cd blockchain/hedera-energy-trading

# Initialize token
npm run init

# Copy token ID to .env
# Edit .env and add: TEC_TOKEN_ID=0.0.XXXXXXX

# Restart server
npm start
```

### Issue: Flutter app can't connect

**Solution:**

For **Android Emulator**:
```dart
// In lib/services/api_service.dart
static String baseUrl = 'http://10.0.2.2:3000';
```

For **iOS Simulator**:
```dart
static String baseUrl = 'http://localhost:3000';
```

For **Physical Device**:
```dart
// Use your computer's IP address
static String baseUrl = 'http://192.168.1.XXX:3000';
```

### Issue: Profile shows no data

**Solution:**
```bash
# 1. Check backend is running
curl http://localhost:3000/api/health

# 2. Check factory exists
curl http://localhost:3000/api/factory/YOUR_FACTORY_ID

# 3. Check you're logged in with correct factory ID

# 4. Pull to refresh on profile screen
```

### Issue: Still see 0.00 TEC balance

**Solution:**
```bash
# 1. Check database has data
psql -d ecoguardians -c "SELECT factoryId, currencyBalance FROM factories;"

# 2. If balance is 0, register was done before fix
# Solution: Register a new factory with initial balance

# 3. Pull to refresh on profile screen
```

## 📚 Additional Resources

- **Complete Troubleshooting**: See `TROUBLESHOOTING.md`
- **Detailed Changes**: See `FIX_SUMMARY.md`
- **PostgreSQL Setup**: See `POSTGRESQL_MIGRATION.md`
- **Full Documentation**: See `README.md`

## 🆘 Need Help?

1. Check the TROUBLESHOOTING.md guide
2. Review backend logs for errors
3. Check PostgreSQL logs:
   ```bash
   tail -f /var/log/postgresql/postgresql-*.log  # Linux
   tail -f /opt/homebrew/var/log/postgresql@15.log  # macOS
   ```
4. Enable Flutter debug mode and check console output

## 🎉 Success Criteria

You'll know everything is working when:

✅ Backend starts without errors
✅ Health endpoint returns OK: `curl http://localhost:3000/api/health`
✅ Config endpoint returns token ID: `curl http://localhost:3000/api/config`
✅ Can register new factory via Flutter app
✅ Profile shows all data (Hedera ID, Token ID, balance)
✅ Can sign out and login again
✅ Pull-to-refresh updates data
✅ Balance shows correct amount (not 0)

---

**Congratulations!** 🎊 Your EcoGuardians application is now fully functional with all fixes applied.

For any issues, refer to `TROUBLESHOOTING.md` or check the backend logs.
