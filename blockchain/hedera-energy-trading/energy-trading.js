/**
 * Energy Trading Operations on Hedera
 * Core business logic for energy token operations using TEC
 */

const bcrypt = require('bcrypt');
const {
  TransferTransaction,
  AccountBalanceQuery,
  TopicCreateTransaction,
  TopicMessageSubmitTransaction,
  TokenId,
  AccountId
} = require("@hashgraph/sdk");
const { initializeHederaClient, createFactoryAccount, associateTokenWithAccount, transferTokensBetweenAccounts, mintTECTokens } = require("./hedera-client");
const { getDatabase, dbRun, dbGet, dbAll } = require("./database");

// Get TEC token ID from environment
const TEC_TOKEN_ID = process.env.TEC_TOKEN_ID;

// TEC token has 2 decimal places, so we multiply by 100 to get the smallest unit
const TEC_DECIMAL_MULTIPLIER = 100;

/**
 * Initialize Hedera Topic for immutable transaction records
 */
async function createEnergyTradingTopic() {
  const { client } = initializeHederaClient();
  
  try {
    const topicCreateTx = await new TopicCreateTransaction()
      .setTopicMemo("Energy Trading Transaction Log")
      .execute(client);
    
    const receipt = await topicCreateTx.getReceipt(client);
    const topicId = receipt.topicId;
    
    console.log(`✓ Energy Trading Topic created: ${topicId}`);
    return topicId;
  } finally {
    client.close();
  }
}

/**
 * Log transaction to Hedera Consensus Service
 */
async function logToHederaTopic(topicId, message) {
  const { client } = initializeHederaClient();
  
  try {
    const submitTx = await new TopicMessageSubmitTransaction()
      .setTopicId(topicId)
      .setMessage(JSON.stringify(message))
      .execute(client);
    
    const receipt = await submitTx.getReceipt(client);
    return receipt.status.toString();
  } finally {
    client.close();
  }
}

/**
 * Register a new factory
 */
async function registerFactory(factoryData) {
  const { factoryId, name, passwordHash, initialBalance, energyType, currencyBalance, dailyConsumption, availableEnergy } = factoryData;
  
  const db = await getDatabase();
  
  try {
    // Check if factory already exists
    const existing = await dbGet(db, 'SELECT factoryId FROM factories WHERE factoryId = $1', [factoryId]);
    if (existing) {
      throw new Error(`Factory ${factoryId} already exists`);
    }

    // Create Hedera account for the factory
    let hederaAccountId = null;
    let hederaPrivateKey = null;
    let initialTecTransferTxId = null;
    
    if (TEC_TOKEN_ID) {
      try {
        console.log(`Creating Hedera account for factory ${factoryId}...`);
        const accountInfo = await createFactoryAccount(10); // 10 HBAR initial balance
        hederaAccountId = accountInfo.accountId;
        hederaPrivateKey = accountInfo.privateKey;

        // Associate the account with TEC token
        console.log(`Associating TEC token with account ${hederaAccountId}...`);
        await associateTokenWithAccount(hederaAccountId, hederaPrivateKey, TEC_TOKEN_ID);
        
        // Transfer initial TEC amount from treasury to factory
        if (currencyBalance && currencyBalance > 0) {
          const { operatorKey, treasuryId } = initializeHederaClient();
          
          // Get treasury private key from environment
          const treasuryPrivateKey = process.env.MY_PRIVATE_KEY;
          
          if (!treasuryPrivateKey) {
            throw new Error('Treasury private key not found in environment');
          }
          
          console.log(`Transferring initial ${currencyBalance} TEC from treasury to factory ${factoryId}...`);
          
          // Convert TEC amount to smallest unit
          const tecAmountInSmallestUnit = Math.floor(currencyBalance * TEC_DECIMAL_MULTIPLIER);
          
          initialTecTransferTxId = await transferTokensBetweenAccounts(
            treasuryId,
            treasuryPrivateKey,
            hederaAccountId,
            TEC_TOKEN_ID,
            tecAmountInSmallestUnit
          );
          
          console.log(`✓ Initial TEC transfer completed: ${initialTecTransferTxId}`);
        }
        
        // TODO: Add account cleanup if token association fails
        // Current limitation: If association fails, the account is orphaned with 10 HBAR
        // Future improvement: Delete account and recover HBAR on failure
      } catch (error) {
        console.error('Failed to create Hedera account or associate token:', error.message);
        throw new Error(`Failed to setup Hedera account: ${error.message}`);
      }
    }

    // Insert factory into database
    await dbRun(db, `
      INSERT INTO factories (factoryId, name, passwordHash, hederaAccountId, hederaPrivateKey, energyType, energyBalance, currencyBalance, dailyConsumption, availableEnergy)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
    `, [factoryId, name, passwordHash, hederaAccountId, hederaPrivateKey, energyType, initialBalance || 0, currencyBalance || 0, dailyConsumption || 0, availableEnergy || 0]);

    // Record transaction history
    await dbRun(db, `
      INSERT INTO transaction_history (factoryId, transactionType, amount, hederaTransactionId)
      VALUES ($1, 'REGISTER', $2, $3)
    `, [factoryId, initialBalance || 0, initialTecTransferTxId]);

    return {
      factoryId,
      name,
      hederaAccountId,
      energyType,
      energyBalance: initialBalance || 0,
      currencyBalance: currencyBalance || 0,
      dailyConsumption: dailyConsumption || 0,
      availableEnergy: availableEnergy || 0,
      initialTecTransferTxId
    };
  } finally {
    }
}

/**
 * Mint energy tokens (add surplus energy)
 * Also mints corresponding TEC tokens on Hedera blockchain
 * and transfers them from treasury to factory account
 */
async function mintEnergyTokens(factoryId, amount) {
  if (amount <= 0) {
    throw new Error('Amount must be positive');
  }

  const db = await getDatabase();
  
  try {
    // Get factory
    const factory = await dbGet(db, 'SELECT * FROM factories WHERE factoryId = $1', [factoryId]);
    if (!factory) {
      throw new Error(`Factory ${factoryId} not found`);
    }

    // Mint TEC tokens on Hedera if token is configured
    let hederaMintTxId = null;
    let hederaTransferTxId = null;
    
    if (TEC_TOKEN_ID) {
      // Validate token ID format
      if (!/^0\.0\.\d+$/.test(TEC_TOKEN_ID)) {
        throw new Error(`Invalid TEC_TOKEN_ID format: ${TEC_TOKEN_ID}. Expected format: 0.0.xxxxx`);
      }
      
      try {
        console.log(`\n=== Minting TEC tokens for ${factoryId} ===`);
        
        // Convert energy amount to TEC tokens (in smallest unit)
        // For renewable energy, 1 kWh of energy = equivalent TEC value
        // With 2 decimals, multiply by 100 to get smallest unit
        const tecAmountInSmallestUnit = Math.floor(amount * TEC_DECIMAL_MULTIPLIER);
        
        console.log(`Minting ${amount} TEC (${tecAmountInSmallestUnit} in smallest unit) on Hedera blockchain...`);
        
        hederaMintTxId = await mintTECTokens(TEC_TOKEN_ID, tecAmountInSmallestUnit);
        
        console.log(`=== TEC tokens minted successfully ===\n`);
        
        // Transfer minted TEC from treasury to factory account
        if (factory.hederaAccountId && factory.hederaPrivateKey) {
          const { treasuryId } = initializeHederaClient();
          const treasuryPrivateKey = process.env.MY_PRIVATE_KEY;
          
          if (!treasuryPrivateKey) {
            throw new Error('Treasury private key not found in environment');
          }
          
          console.log(`\n=== Transferring minted TEC from treasury to factory ${factoryId} ===`);
          console.log(`Transferring ${amount} TEC from treasury to factory account ${factory.hederaAccountId}...`);
          
          hederaTransferTxId = await transferTokensBetweenAccounts(
            treasuryId,
            treasuryPrivateKey,
            factory.hederaAccountId,
            TEC_TOKEN_ID,
            tecAmountInSmallestUnit
          );
          
          console.log(`✓ TEC transfer to factory completed: ${hederaTransferTxId}`);
          console.log(`=== Transfer completed successfully ===\n`);
        } else {
          console.warn(`Warning: Factory ${factoryId} does not have a Hedera account. TEC remains in treasury.`);
        }
        
      } catch (error) {
        // Fail the entire operation if Hedera minting or transfer fails
        throw new Error(`Failed to mint/transfer ${amount} TEC tokens for factory ${factoryId} on Hedera: ${error.message}`);
      }
    }

    // Update energy balance and currency balance in local database
    // Note: 1:1 ratio - minting 1 kWh of energy also credits 1 TEC token
    const newEnergyBalance = factory.energyBalance + amount;
    const newCurrencyBalance = factory.currencyBalance + amount;
    
    await dbRun(db, 'UPDATE factories SET energyBalance = $1, currencyBalance = $2, updatedAt = EXTRACT(EPOCH FROM NOW()) WHERE factoryId = $3', 
      [newEnergyBalance, newCurrencyBalance, factoryId]);

    // Record transaction history for mint
    await dbRun(db, `
      INSERT INTO transaction_history (factoryId, transactionType, amount, hederaTransactionId)
      VALUES ($1, 'MINT', $2, $3)
    `, [factoryId, amount, hederaMintTxId]);
    
    // Record transaction history for transfer if it occurred
    if (hederaTransferTxId) {
      await dbRun(db, `
        INSERT INTO transaction_history (factoryId, transactionType, amount, hederaTransactionId)
        VALUES ($1, 'TEC_TRANSFER_IN', $2, $3)
      `, [factoryId, amount, hederaTransferTxId]);
    }

    return {
      factoryId,
      previousBalance: factory.energyBalance,
      newBalance: newEnergyBalance,
      minted: amount,
      hederaMintTransactionId: hederaMintTxId,
      hederaTransferTransactionId: hederaTransferTxId,
      currencyBalance: newCurrencyBalance
    };
  } finally {
    }
}

/**
 * Transfer energy between factories
 */
async function transferEnergy(fromFactoryId, toFactoryId, amount) {
  if (amount <= 0) {
    throw new Error('Amount must be positive');
  }

  const db = await getDatabase();
  
  try {
    // Get both factories (each query is independent with its own parameter array)
    const fromFactory = await dbGet(db, 'SELECT * FROM factories WHERE factoryId = $1', [fromFactoryId]);
    const toFactory = await dbGet(db, 'SELECT * FROM factories WHERE factoryId = $1', [toFactoryId]);

    if (!fromFactory) throw new Error(`Factory ${fromFactoryId} not found`);
    if (!toFactory) throw new Error(`Factory ${toFactoryId} not found`);

    // Check balance
    if (fromFactory.energyBalance < amount) {
      throw new Error(`Insufficient energy balance: has ${fromFactory.energyBalance}, needs ${amount}`);
    }

    // Update balances
    await dbRun(db, 'UPDATE factories SET energyBalance = energyBalance - $1, updatedAt = EXTRACT(EPOCH FROM NOW()) WHERE factoryId = $2',
      [amount, fromFactoryId]);
    await dbRun(db, 'UPDATE factories SET energyBalance = energyBalance + $1, updatedAt = EXTRACT(EPOCH FROM NOW()) WHERE factoryId = $2',
      [amount, toFactoryId]);

    // Record transaction history
    await dbRun(db, `
      INSERT INTO transaction_history (factoryId, transactionType, amount, relatedFactoryId)
      VALUES ($1, 'TRANSFER_OUT', $2, $3)
    `, [fromFactoryId, amount, toFactoryId]);
    
    await dbRun(db, `
      INSERT INTO transaction_history (factoryId, transactionType, amount, relatedFactoryId)
      VALUES ($1, 'TRANSFER_IN', $2, $3)
    `, [toFactoryId, amount, fromFactoryId]);

    return {
      fromFactoryId,
      toFactoryId,
      amount,
      success: true
    };
  } finally {
    }
}

/**
 * Create an energy trade
 */
async function createEnergyTrade(tradeData) {
  const { tradeId, sellerId, buyerId, amount, pricePerUnit } = tradeData;
  
  const db = await getDatabase();
  
  try {
    // Check if trade exists
    const existing = await dbGet(db, 'SELECT tradeId FROM trades WHERE tradeId = $1', [tradeId]);
    if (existing) {
      throw new Error(`Trade ${tradeId} already exists`);
    }

    // Validate seller and buyer exist
    const seller = await dbGet(db, 'SELECT * FROM factories WHERE factoryId = $1', [sellerId]);
    const buyer = await dbGet(db, 'SELECT * FROM factories WHERE factoryId = $1', [buyerId]);

    if (!seller) throw new Error(`Seller factory ${sellerId} not found`);
    if (!buyer) throw new Error(`Buyer factory ${buyerId} not found`);

    // Check seller has enough energy
    if (seller.energyBalance < amount) {
      throw new Error(`Seller has insufficient energy balance`);
    }

    const totalPrice = amount * pricePerUnit;

    // Insert trade
    await dbRun(db, `
      INSERT INTO trades (tradeId, sellerId, buyerId, amount, pricePerUnit, totalPrice, status)
      VALUES ($1, $2, $3, $4, $5, $6, 'pending')
    `, [tradeId, sellerId, buyerId, amount, pricePerUnit, totalPrice]);

    return {
      tradeId,
      sellerId,
      buyerId,
      amount,
      pricePerUnit,
      totalPrice,
      status: 'pending'
    };
  } finally {
    }
}

/**
 * Execute a pending trade with TEC token transfer
 */
async function executeTrade(tradeId) {
  const db = await getDatabase();
  
  try {
    // Get trade
    const trade = await dbGet(db, 'SELECT * FROM trades WHERE tradeId = $1', [tradeId]);
    if (!trade) {
      throw new Error(`Trade ${tradeId} not found`);
    }

    if (trade.status === 'completed') {
      throw new Error('Trade already completed');
    }

    // Get buyer and seller
    const buyer = await dbGet(db, 'SELECT * FROM factories WHERE factoryId = $1', [trade.buyerId]);
    const seller = await dbGet(db, 'SELECT * FROM factories WHERE factoryId = $1', [trade.sellerId]);

    // Validate Hedera accounts exist
    if (TEC_TOKEN_ID) {
      if (!buyer.hederaAccountId || !buyer.hederaPrivateKey) {
        throw new Error(`Buyer factory ${trade.buyerId} does not have a Hedera account`);
      }
      if (!seller.hederaAccountId) {
        throw new Error(`Seller factory ${trade.sellerId} does not have a Hedera account`);
      }
    }

    // Check buyer has enough TEC
    if (buyer.currencyBalance < trade.totalPrice) {
      throw new Error(`Buyer has insufficient TEC balance: has ${buyer.currencyBalance}, needs ${trade.totalPrice}`);
    }

    // Execute real TEC token transfer on Hedera
    let hederaTxId = null;
    if (TEC_TOKEN_ID) {
      try {
        console.log(`\n=== Executing Trade ${trade.tradeId} on Hedera ===`);
        hederaTxId = await transferTECOnHedera(buyer, seller, trade.totalPrice);
        console.log(`=== Trade ${trade.tradeId} completed on Hedera ===\n`);
      } catch (error) {
        // No rollback needed - database hasn't been updated yet
        throw new Error(`Hedera TEC transfer failed: ${error.message}`);
      }
    }

    // Update local balances after successful Hedera transfer
    // Transfer energy
    await dbRun(db, 'UPDATE factories SET energyBalance = energyBalance - $1 WHERE factoryId = $2',
      [trade.amount, trade.sellerId]);
    await dbRun(db, 'UPDATE factories SET energyBalance = energyBalance + $1 WHERE factoryId = $2',
      [trade.amount, trade.buyerId]);

    // Transfer TEC (currency) - update local tracking
    await dbRun(db, 'UPDATE factories SET currencyBalance = currencyBalance - $1 WHERE factoryId = $2',
      [trade.totalPrice, trade.buyerId]);
    await dbRun(db, 'UPDATE factories SET currencyBalance = currencyBalance + $1 WHERE factoryId = $2',
      [trade.totalPrice, trade.sellerId]);

    // Update trade status
    await dbRun(db, 'UPDATE trades SET status = $1, hederaTransactionId = $2 WHERE tradeId = $3',
      ['completed', hederaTxId, tradeId]);

    // Record transaction history
    await dbRun(db, `
      INSERT INTO transaction_history (factoryId, transactionType, amount, relatedFactoryId, hederaTransactionId)
      VALUES ($1, 'TRADE_SELL', $2, $3, $4)
    `, [trade.sellerId, trade.amount, trade.buyerId, hederaTxId]);
    
    await dbRun(db, `
      INSERT INTO transaction_history (factoryId, transactionType, amount, relatedFactoryId, hederaTransactionId)
      VALUES ($1, 'TRADE_BUY', $2, $3, $4)
    `, [trade.buyerId, trade.amount, trade.sellerId, hederaTxId]);

    return {
      tradeId,
      status: 'completed',
      hederaTransactionId: hederaTxId
    };
  } finally {
    }
}

/**
 * Transfer TEC tokens on Hedera network
 * 
 * This function executes real TransferTransaction on Hedera network
 * to transfer TEC tokens between factory accounts.
 * 
 * @param {Object} fromAccount - Factory sending TEC
 * @param {Object} toAccount - Factory receiving TEC
 * @param {number} amount - Amount of TEC to transfer (will be converted to token smallest unit)
 * @returns {string} Transaction ID from Hedera
 */
async function transferTECOnHedera(fromAccount, toAccount, amount) {
  if (!TEC_TOKEN_ID) {
    throw new Error('TEC_TOKEN_ID not configured');
  }

  if (!fromAccount.hederaAccountId || !fromAccount.hederaPrivateKey) {
    throw new Error(`Sender factory ${fromAccount.factoryId} does not have a Hedera account`);
  }

  if (!toAccount.hederaAccountId) {
    throw new Error(`Receiver factory ${toAccount.factoryId} does not have a Hedera account`);
  }

  // Convert amount to token smallest unit (TEC has 2 decimals)
  // e.g., 100 TEC = 10000 in smallest unit
  // Math.floor ensures we don't send fractional smallest units which are not allowed
  const amountInSmallestUnit = Math.floor(amount * TEC_DECIMAL_MULTIPLIER);

  console.log(`Executing real TEC transfer: ${amount} TEC from ${fromAccount.factoryId} to ${toAccount.factoryId}`);
  console.log(`  From Account: ${fromAccount.hederaAccountId}`);
  console.log(`  To Account: ${toAccount.hederaAccountId}`);
  console.log(`  Amount: ${amountInSmallestUnit} (smallest unit)`);

  try {
    const transactionId = await transferTokensBetweenAccounts(
      fromAccount.hederaAccountId,
      fromAccount.hederaPrivateKey,
      toAccount.hederaAccountId,
      TEC_TOKEN_ID,
      amountInSmallestUnit
    );

    console.log(`✓ TEC transfer successful on Hedera`);
    console.log(`  Transaction ID: ${transactionId}`);
    console.log(`  View on HashScan: https://hashscan.io/testnet/transaction/${transactionId}`);

    return transactionId;
  } catch (error) {
    console.error('Hedera TEC transfer failed:', error.message);
    throw new Error(`Hedera transfer failed: ${error.message}`);
  }
}

/**
 * Get factory information
 */
async function getFactory(factoryId) {
  const db = await getDatabase();
  
  try {
    const factory = await dbGet(db, 'SELECT * FROM factories WHERE factoryId = $1', [factoryId]);
    if (!factory) {
      throw new Error(`Factory ${factoryId} not found`);
    }
    return factory;
  } finally {
    }
}

/**
 * Get all factories
 */
async function getAllFactories() {
  const db = await getDatabase();
  
  try {
    return await dbAll(db, 'SELECT * FROM factories ORDER BY factoryId');
  } finally {
    }
}

/**
 * Get trade information
 */
async function getTrade(tradeId) {
  const db = await getDatabase();
  
  try {
    const trade = await dbGet(db, 'SELECT * FROM trades WHERE tradeId = $1', [tradeId]);
    if (!trade) {
      throw new Error(`Trade ${tradeId} not found`);
    }
    return trade;
  } finally {
    }
}

/**
 * Get factory transaction history
 */
async function getFactoryHistory(factoryId) {
  const db = await getDatabase();
  
  try {
    return await dbAll(db, 
      'SELECT * FROM transaction_history WHERE factoryId = $1 ORDER BY timestamp DESC',
      [factoryId]
    );
  } finally {
    }
}

/**
 * Update available energy
 */
async function updateAvailableEnergy(factoryId, newAvailableEnergy) {
  if (newAvailableEnergy < 0) {
    throw new Error('Available energy cannot be negative');
  }

  const db = await getDatabase();
  
  try {
    const factory = await dbGet(db, 'SELECT * FROM factories WHERE factoryId = $1', [factoryId]);
    if (!factory) {
      throw new Error(`Factory ${factoryId} not found`);
    }

    await dbRun(db, 'UPDATE factories SET availableEnergy = $1, updatedAt = EXTRACT(EPOCH FROM NOW()) WHERE factoryId = $2',
      [newAvailableEnergy, factoryId]);

    return { factoryId, availableEnergy: newAvailableEnergy };
  } finally {
    }
}

/**
 * Update daily consumption
 */
async function updateDailyConsumption(factoryId, newDailyConsumption) {
  if (newDailyConsumption < 0) {
    throw new Error('Daily consumption cannot be negative');
  }

  const db = await getDatabase();
  
  try {
    const factory = await dbGet(db, 'SELECT * FROM factories WHERE factoryId = $1', [factoryId]);
    if (!factory) {
      throw new Error(`Factory ${factoryId} not found`);
    }

    await dbRun(db, 'UPDATE factories SET dailyConsumption = $1, updatedAt = EXTRACT(EPOCH FROM NOW()) WHERE factoryId = $2',
      [newDailyConsumption, factoryId]);

    return { factoryId, dailyConsumption: newDailyConsumption };
  } finally {
    }
}

/**
 * Get energy status (surplus/deficit)
 */
async function getEnergyStatus(factoryId) {
  const db = await getDatabase();
  
  try {
    const factory = await dbGet(db, 'SELECT * FROM factories WHERE factoryId = $1', [factoryId]);
    if (!factory) {
      throw new Error(`Factory ${factoryId} not found`);
    }

    const difference = factory.availableEnergy - factory.dailyConsumption;
    let status;
    
    if (difference > 0) {
      status = 'surplus';
    } else if (difference < 0) {
      status = 'deficit';
    } else {
      status = 'balanced';
    }

    return {
      factoryId: factory.factoryId,
      factoryName: factory.name,
      availableEnergy: factory.availableEnergy,
      dailyConsumption: factory.dailyConsumption,
      difference,
      status
    };
  } finally {
    }
}

/**
 * Login factory with password authentication
 */
async function loginFactory(factoryId, password) {
  const db = await getDatabase();
  
  try {
    if (!password || typeof password !== 'string') {
      throw new Error('Password is required and must be a string');
    }

    const factory = await dbGet(db, 'SELECT * FROM factories WHERE factoryId = $1', [factoryId]);
    if (!factory) {
      throw new Error('Invalid factory ID or password');
    }

    if (!factory.passwordHash) {
      // Fix for factories that were created without password hashes
      console.warn(`⚠️ WARNING: Factory ${factoryId} has no password hash. Auto-fixing by setting password hash from provided password.`);
      
      // Hash the provided password and update the database
      const saltRounds = 10;
      const passwordHash = await bcrypt.hash(password, saltRounds);
      
      await dbRun(db, 'UPDATE factories SET passwordHash = $1 WHERE factoryId = $2', [passwordHash, factoryId]);
      
      console.log(`✓ Password hash updated for factory ${factoryId}`);
    } else {
      // Verify password
      const passwordMatch = await bcrypt.compare(password, factory.passwordHash);
      if (!passwordMatch) {
        throw new Error('Invalid factory ID or password');
      }
    }

    // Get updated factory data
    const updatedFactory = await dbGet(db, 'SELECT * FROM factories WHERE factoryId = $1', [factoryId]);

    // Return factory data without sensitive information
    return {
      factoryId: updatedFactory.factoryId,
      name: updatedFactory.name,
      hederaAccountId: updatedFactory.hederaAccountId,
      energyType: updatedFactory.energyType,
      energyBalance: updatedFactory.energyBalance,
      currencyBalance: updatedFactory.currencyBalance,
      dailyConsumption: updatedFactory.dailyConsumption,
      availableEnergy: updatedFactory.availableEnergy,
      createdAt: updatedFactory.createdAt
    };
  } catch (error) {
    console.error('Login error:', error.message);
    throw error;
  }
}

module.exports = {
  createEnergyTradingTopic,
  logToHederaTopic,
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
};

