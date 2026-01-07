/**
 * Hedera Energy Trading REST API Server
 * Provides HTTP endpoints for energy trading operations using TEC token
 */

const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const bcrypt = require('bcrypt');
const { initDatabase } = require('./database');
const {
  registerFactory,
  mintEnergyTokens,
  transferEnergy,
  createEnergyTrade,
  executeTrade,
  getFactory,
  getAllFactories,
  getTrade,
  getFactoryHistory,
  getFactoryTrades,
  updateAvailableEnergy,
  updateDailyConsumption,
  getEnergyStatus,
  loginFactory,
  changeFactoryPassword
} = require('./energy-trading');
const {
  getTreasuryTransactions,
  getLatestBlockInfo,
  getTreasuryBalance
} = require('./hedera-client');

// Initialize Express application
const app = express();

app.use(cors());
app.use(bodyParser.json());

// Configuration
const PORT = process.env.PORT || 3000;

/**
 * Initialize database on startup
 * Uses a promise to prevent race conditions from concurrent requests
 */
let dbInitPromise = null;

async function ensureDatabase() {
  if (!dbInitPromise) {
    dbInitPromise = initDatabase();
  }
  await dbInitPromise;
}

/**
 * API Routes
 */

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'Hedera Energy Trading API is running',
    blockchain: 'Hedera Hashgraph',
    token: 'TEC (Tunisian Energy Coin)',
    timestamp: new Date().toISOString()
  });
});

/**
 * Get system configuration (token ID)
 * GET /api/config
 */
app.get('/api/config', (req, res) => {
  res.json({
    success: true,
    data: {
      tecTokenId: process.env.TEC_TOKEN_ID || null,
      blockchain: 'Hedera Hashgraph Testnet',
      tokenName: 'TEC (Tunisian Energy Coin)'
    }
  });
});

/**
 * Register a new factory in the industrial zone
 * POST /api/factory/register
 * Body: { factoryId, name, password, initialBalance, energyType, currencyBalance, dailyConsumption, availableEnergy }
 */
app.post('/api/factory/register', async (req, res) => {
  try {
    await ensureDatabase();

    const { factoryId, name, password, initialBalance, energyType, currencyBalance, dailyConsumption, availableEnergy } = req.body;

    // Validate required fields
    if (!factoryId || !name || !password || !energyType) {
      return res.status(400).json({ error: 'Missing required fields: factoryId, name, password, energyType' });
    }

    // Validate password strength
    if (password.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters long' });
    }

    // Validate numeric fields
    const initBalNum = initialBalance === undefined ? 0 : Number(initialBalance);
    const currencyBalNum = currencyBalance === undefined ? 0 : Number(currencyBalance);
    const dailyConsNum = dailyConsumption === undefined ? 0 : Number(dailyConsumption);
    const availableNum = availableEnergy === undefined ? initBalNum : Number(availableEnergy);

    if (isNaN(initBalNum) || initBalNum < 0) {
      return res.status(400).json({ error: 'initialBalance must be a non-negative number' });
    }

    // Hash password
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    const factoryData = {
      factoryId,
      name,
      passwordHash,
      initialBalance: initBalNum,
      energyType,
      currencyBalance: currencyBalNum,
      dailyConsumption: dailyConsNum,
      availableEnergy: availableNum
    };

    const result = await registerFactory(factoryData);

    res.json({
      success: true,
      message: `Factory ${factoryId} registered successfully on Hedera network`,
      data: result
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Login with factory ID and password
 * POST /api/factory/login
 * Body: { factoryId, password }
 */
app.post('/api/factory/login', async (req, res) => {
  try {
    await ensureDatabase();

    const { factoryId, password } = req.body;

    // Validate required fields
    if (!factoryId || !password) {
      return res.status(400).json({ error: 'Missing required fields: factoryId, password' });
    }

    const result = await loginFactory(factoryId, password);

    res.json({
      success: true,
      message: `Factory ${factoryId} authenticated successfully`,
      data: result
    });
  } catch (error) {
    res.status(401).json({ error: error.message });
  }
});

/**
 * Mint energy tokens when factory generates surplus energy
 * POST /api/energy/mint
 * Body: { factoryId, amount }
 */
app.post('/api/energy/mint', async (req, res) => {
  try {
    await ensureDatabase();

    const { factoryId, amount } = req.body;

    // Validate input
    if (!factoryId || !amount || amount <= 0) {
      return res.status(400).json({ error: 'Invalid factoryId or amount' });
    }

    const result = await mintEnergyTokens(factoryId, Number(amount));

    res.json({
      success: true,
      message: `Minted ${amount} kWh of energy tokens for ${factoryId}`,
      data: result
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Transfer energy tokens between factories
 * POST /api/energy/transfer
 * Body: { fromFactoryId, toFactoryId, amount }
 */
app.post('/api/energy/transfer', async (req, res) => {
  try {
    await ensureDatabase();

    const { fromFactoryId, toFactoryId, amount } = req.body;

    // Validate input
    if (!fromFactoryId || !toFactoryId || !amount || amount <= 0) {
      return res.status(400).json({ error: 'Invalid input parameters' });
    }

    const result = await transferEnergy(fromFactoryId, toFactoryId, Number(amount));

    res.json({
      success: true,
      message: `Transferred ${amount} kWh from ${fromFactoryId} to ${toFactoryId}`,
      data: result
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Create an energy trade between factories
 * POST /api/trade/create
 * Body: { tradeId, sellerId, buyerId, amount, pricePerUnit }
 */
app.post('/api/trade/create', async (req, res) => {
  try {
    await ensureDatabase();

    const { tradeId, sellerId, buyerId, amount, pricePerUnit } = req.body;

    // Validate input
    if (!tradeId || !sellerId || !buyerId || !amount || !pricePerUnit) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const tradeData = {
      tradeId,
      sellerId,
      buyerId,
      amount: Number(amount),
      pricePerUnit: Number(pricePerUnit)
    };

    const result = await createEnergyTrade(tradeData);

    res.json({
      success: true,
      message: `Trade ${tradeId} created successfully (payment in TEC)`,
      data: result
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Execute a pending energy trade (with TEC payment)
 * POST /api/trade/execute
 * Body: { tradeId }
 */
app.post('/api/trade/execute', async (req, res) => {
  try {
    await ensureDatabase();

    const { tradeId } = req.body;

    if (!tradeId) {
      return res.status(400).json({ error: 'Trade ID is required' });
    }

    const result = await executeTrade(tradeId);

    res.json({
      success: true,
      message: `Trade ${tradeId} executed successfully with TEC payment`,
      data: result
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Get factory information
 * GET /api/factory/:factoryId
 */
app.get('/api/factory/:factoryId', async (req, res) => {
  try {
    await ensureDatabase();

    const { factoryId } = req.params;
    const factory = await getFactory(factoryId);

    res.json({ success: true, data: factory });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Get energy balance of a factory
 * GET /api/factory/:factoryId/balance
 */
app.get('/api/factory/:factoryId/balance', async (req, res) => {
  try {
    await ensureDatabase();

    const { factoryId } = req.params;
    const factory = await getFactory(factoryId);

    res.json({
      success: true,
      data: {
        factoryId,
        energyBalance: factory.energyBalance,
        currencyBalance: factory.currencyBalance
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Get available energy of a factory
 * GET /api/factory/:factoryId/available-energy
 */
app.get('/api/factory/:factoryId/available-energy', async (req, res) => {
  try {
    await ensureDatabase();

    const { factoryId } = req.params;
    const factory = await getFactory(factoryId);

    res.json({
      success: true,
      data: {
        factoryId,
        availableEnergy: factory.availableEnergy
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Get energy status (surplus/deficit) of a factory
 * GET /api/factory/:factoryId/energy-status
 */
app.get('/api/factory/:factoryId/energy-status', async (req, res) => {
  try {
    await ensureDatabase();

    const { factoryId } = req.params;
    const status = await getEnergyStatus(factoryId);

    res.json({ success: true, data: status });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Update available energy of a factory
 * PUT /api/factory/:factoryId/available-energy
 * Body: { availableEnergy }
 */
app.put('/api/factory/:factoryId/available-energy', async (req, res) => {
  try {
    await ensureDatabase();

    const { factoryId } = req.params;
    const { availableEnergy } = req.body;

    if (availableEnergy === undefined || availableEnergy < 0) {
      return res.status(400).json({ error: 'Invalid availableEnergy value' });
    }

    const result = await updateAvailableEnergy(factoryId, Number(availableEnergy));

    res.json({
      success: true,
      message: `Available energy updated for ${factoryId}`,
      data: result
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Update daily consumption of a factory
 * PUT /api/factory/:factoryId/daily-consumption
 * Body: { dailyConsumption }
 */
app.put('/api/factory/:factoryId/daily-consumption', async (req, res) => {
  try {
    await ensureDatabase();

    const { factoryId } = req.params;
    const { dailyConsumption } = req.body;

    if (dailyConsumption === undefined || dailyConsumption < 0) {
      return res.status(400).json({ error: 'Invalid dailyConsumption value' });
    }

    const result = await updateDailyConsumption(factoryId, Number(dailyConsumption));

    res.json({
      success: true,
      message: `Daily consumption updated for ${factoryId}`,
      data: result
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Change factory password
 * PUT /api/factory/:factoryId/password
 * Body: { currentPassword, newPassword }
 */
app.put('/api/factory/:factoryId/password', async (req, res) => {
  try {
    await ensureDatabase();

    const { factoryId } = req.params;
    const { currentPassword, newPassword } = req.body;

    // Validate required fields
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ error: 'Missing required fields: currentPassword, newPassword' });
    }

    const result = await changeFactoryPassword(factoryId, currentPassword, newPassword);

    res.json({
      success: true,
      message: 'Password changed successfully',
      data: result
    });
  } catch (error) {
    // Return 401 for authentication errors, 400 for validation errors
    if (error.message.includes('incorrect') || error.message.includes('not found')) {
      res.status(401).json({ error: error.message });
    } else if (error.message.includes('at least')) {
      res.status(400).json({ error: error.message });
    } else {
      res.status(500).json({ error: error.message });
    }
  }
});

/**
 * Get all factories in the industrial zone
 * GET /api/factories
 */
app.get('/api/factories', async (req, res) => {
  try {
    await ensureDatabase();

    const factories = await getAllFactories();

    res.json({
      success: true,
      count: factories.length,
      data: factories
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Get trade information
 * GET /api/trade/:tradeId
 */
app.get('/api/trade/:tradeId', async (req, res) => {
  try {
    await ensureDatabase();

    const { tradeId } = req.params;
    const trade = await getTrade(tradeId);

    res.json({ success: true, data: trade });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Get factory transaction history
 * GET /api/factory/:factoryId/history
 */
app.get('/api/factory/:factoryId/history', async (req, res) => {
  try {
    await ensureDatabase();

    const { factoryId } = req.params;
    const history = await getFactoryHistory(factoryId);

    res.json({ success: true, data: history });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Get factory trades (as buyer or seller)
 * GET /api/factory/:factoryId/trades
 */
app.get('/api/factory/:factoryId/trades', async (req, res) => {
  try {
    await ensureDatabase();

    const { factoryId } = req.params;
    const trades = await getFactoryTrades(factoryId);

    res.json({ success: true, data: trades });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Get treasury account transactions from Hedera testnet
 * GET /api/treasury/transactions
 * Query params: limit (optional, default: 20)
 */
app.get('/api/treasury/transactions', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 20;
    
    const transactions = await getTreasuryTransactions(limit);

    res.json({
      success: true,
      count: transactions.length,
      data: transactions
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Get latest block information from Hedera testnet
 * GET /api/blockchain/latest-block
 */
app.get('/api/blockchain/latest-block', async (req, res) => {
  try {
    const blockInfo = await getLatestBlockInfo();

    res.json({
      success: true,
      data: blockInfo
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Get treasury account balance from Hedera testnet
 * GET /api/treasury/balance
 */
app.get('/api/treasury/balance', async (req, res) => {
  try {
    const balance = await getTreasuryBalance();

    res.json({
      success: true,
      data: balance
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
const server = app.listen(PORT, async () => {
  console.log('========================================');
  console.log('   Hedera Energy Trading Network API');
  console.log('========================================');
  console.log(`Server running on http://localhost:${PORT}`);
  console.log('');
  console.log('Blockchain: Hedera Hashgraph');
  console.log('Token: TEC (Tunisian Energy Coin)');
  console.log('');
  console.log('Available endpoints:');
  console.log('  GET  /api/health');
  console.log('  GET  /api/config');
  console.log('  POST /api/factory/register');
  console.log('  POST /api/factory/login');
  console.log('  POST /api/energy/mint');
  console.log('  POST /api/energy/transfer');
  console.log('  POST /api/trade/create');
  console.log('  POST /api/trade/execute');
  console.log('  GET  /api/factory/:factoryId');
  console.log('  GET  /api/factory/:factoryId/balance');
  console.log('  GET  /api/factory/:factoryId/available-energy');
  console.log('  GET  /api/factory/:factoryId/energy-status');
  console.log('  PUT  /api/factory/:factoryId/available-energy');
  console.log('  PUT  /api/factory/:factoryId/daily-consumption');
  console.log('  GET  /api/factories');
  console.log('  GET  /api/trade/:tradeId');
  console.log('  GET  /api/factory/:factoryId/history');
  console.log('  GET  /api/treasury/transactions');
  console.log('  GET  /api/treasury/balance');
  console.log('  GET  /api/blockchain/latest-block');
  console.log('========================================');

  // Initialize database
  try {
    await ensureDatabase();
  } catch (error) {
    console.error('Failed to initialize database:', error);
  }
});

server.on('error', (err) => {
  if (err && err.code === 'EADDRINUSE') {
    console.error(`Port ${PORT} already in use. Start the app with a different PORT or stop the process using this port.`);
    process.exit(1);
  }
  console.error('Server error:', err);
  process.exit(1);
});
