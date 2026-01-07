/**
 * Hedera Energy Trading REST API Server
 * Provides HTTP endpoints for energy trading operations using TEC token
 */

const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const bcrypt = require('bcrypt');
const WebSocket = require('ws');
const http = require('http');
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
  updateAvailableEnergy,
  updateDailyConsumption,
  getEnergyStatus,
  loginFactory
} = require('./energy-trading');

// Initialize Express application
const app = express();

// Create HTTP server for WebSocket support
const server = http.createServer(app);

// WebSocket server for real-time notifications
const wss = new WebSocket.Server({ server });

// Store connected clients per factory: { factoryId: [ws1, ws2, ...] }
const connectedClients = {};

// Store notifications in memory (in production, use Redis or database)
const notifications = {};

app.use(cors());
app.use(bodyParser.json());

// Serve static files
const path = require('path');
app.use(express.static(path.join(__dirname)));

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
 * WebSocket Connection Handler
 */
wss.on('connection', (ws) => {
  console.log('🔌 New WebSocket connection');

  ws.on('message', (data) => {
    try {
      const message = JSON.parse(data);
      
      if (message.type === 'subscribe') {
        const factoryId = message.factoryId;
        console.log(`✓ Factory ${factoryId} subscribed to notifications`);
        
        // Store connection
        if (!connectedClients[factoryId]) {
          connectedClients[factoryId] = [];
        }
        connectedClients[factoryId].push(ws);
        
        // Send any pending notifications
        if (notifications[factoryId]) {
          notifications[factoryId].forEach(notif => {
            ws.send(JSON.stringify(notif));
          });
          notifications[factoryId] = [];
        }
        
        // Confirm subscription
        ws.send(JSON.stringify({
          type: 'subscribed',
          message: `Subscribed to notifications for factory ${factoryId}`
        }));
      }
    } catch (error) {
      console.error('WebSocket message error:', error);
    }
  });

  ws.on('close', () => {
    // Remove client from all subscriptions
    Object.keys(connectedClients).forEach(factoryId => {
      connectedClients[factoryId] = connectedClients[factoryId].filter(client => client !== ws);
      if (connectedClients[factoryId].length === 0) {
        delete connectedClients[factoryId];
      }
    });
    console.log('🔌 WebSocket connection closed');
  });

  ws.on('error', (error) => {
    console.error('WebSocket error:', error);
  });
});

/**
 * Send notification to a factory
 */
function sendNotificationToFactory(factoryId, notification) {
  console.log(`📢 Sending notification to factory ${factoryId}:`, notification.message);
  
  if (connectedClients[factoryId]) {
    connectedClients[factoryId].forEach(client => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(JSON.stringify(notification));
      }
    });
  } else {
    // Store notification for later if client is not connected
    if (!notifications[factoryId]) {
      notifications[factoryId] = [];
    }
    notifications[factoryId].push(notification);
  }
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

    // 📢 Send notification to buyer about the new trade offer
    const notification = {
      type: 'new_trade_offer',
      tradeId: tradeId,
      sellerId: sellerId,
      amount: amount,
      pricePerUnit: pricePerUnit,
      totalPrice: amount * pricePerUnit,
      message: `New energy offer from Factory ${sellerId}: ${amount} kWh at ${pricePerUnit} TEC/kWh (Total: ${amount * pricePerUnit} TEC)`,
      timestamp: new Date().toISOString(),
      status: 'pending'
    };
    
    sendNotificationToFactory(buyerId, notification);

    res.json({
      success: true,
      message: `Trade ${tradeId} created successfully (payment in TEC)`,
      data: result,
      notificationSent: true
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
 * Get notifications for a factory
 * GET /api/notifications/:factoryId
 */
app.get('/api/notifications/:factoryId', async (req, res) => {
  try {
    const { factoryId } = req.params;
    const notifs = notifications[factoryId] || [];
    
    res.json({
      success: true,
      factoryId: factoryId,
      count: notifs.length,
      notifications: notifs
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Clear notifications for a factory
 * DELETE /api/notifications/:factoryId
 */
app.delete('/api/notifications/:factoryId', async (req, res) => {
  try {
    const { factoryId } = req.params;
    const count = notifications[factoryId] ? notifications[factoryId].length : 0;
    notifications[factoryId] = [];
    
    res.json({
      success: true,
      message: `Cleared ${count} notifications for factory ${factoryId}`
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

// Start server with WebSocket support
const httpServer = server.listen(PORT, async () => {
  console.log('========================================');
  console.log('   Hedera Energy Trading Network API');
  console.log('========================================');
  console.log(`Server running on http://localhost:${PORT}`);
  console.log(`WebSocket available on ws://localhost:${PORT}`);
  console.log('');
  console.log('Blockchain: Hedera Hashgraph');
  console.log('Token: TEC (Tunisian Energy Coin)');
  console.log('');
  console.log('Available endpoints:');
  console.log('  GET  /api/health');
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
  console.log('  GET  /api/notifications/:factoryId');
  console.log('');
  console.log('WebSocket:');
  console.log('  Subscribe: {"type": "subscribe", "factoryId": "factory-id"}');
  console.log('========================================');
  
  // Initialize database
  try {
    await ensureDatabase();
  } catch (error) {
    console.error('Failed to initialize database:', error);
  }
});

httpServer.on('error', (err) => {
  if (err && err.code === 'EADDRINUSE') {
    console.error(`Port ${PORT} already in use. Start the app with a different PORT or stop the process using this port.`);
    process.exit(1);
  }
  console.error('Server error:', err);
  process.exit(1);
});
