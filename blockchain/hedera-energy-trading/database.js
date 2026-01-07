/**
 * Database Manager for Energy Trading
 * Manages factory records in PostgreSQL database
 * 
 * SECURITY WARNING: Private keys are stored in plain text in the database.
 * For production use, implement encryption using:
 * - AWS KMS, Azure Key Vault, or HashiCorp Vault for key management
 * - Database-level encryption at rest
 * - Application-level encryption before storing keys
 */

const { Pool } = require('pg');

// PostgreSQL connection pool
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5433,
  database: process.env.DB_NAME || 'ecoguardians',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres'
});

// Log connection details for debugging
console.log(`📊 Database configuration:`);
console.log(`   Host: ${process.env.DB_HOST || 'localhost'}`);
console.log(`   Port: ${process.env.DB_PORT || 5433}`);
console.log(`   Database: ${process.env.DB_NAME || 'ecoguardians'}`);
console.log(`   User: ${process.env.DB_USER || 'postgres'}`);

// Handle pool errors
pool.on('error', (err) => {
  console.error('❌ Unexpected error on idle client', err);
});

/**
 * Initialize database with required tables
 * @returns {Promise<void>} Resolves when database is initialized
 */
async function initDatabase() {
  const client = await pool.connect().catch(err => {
    console.error('❌ Database connection failed:', err.message);
    throw err;
  });
  try {
    // Create factories table
    await client.query(`
      CREATE TABLE IF NOT EXISTS factories (
        factoryId TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        passwordHash TEXT NOT NULL,
        hederaAccountId TEXT,
        hederaPrivateKey TEXT,
        energyType TEXT NOT NULL,
        energyBalance REAL DEFAULT 0,
        currencyBalance REAL DEFAULT 0,
        dailyConsumption REAL DEFAULT 0,
        availableEnergy REAL DEFAULT 0,
        createdAt BIGINT DEFAULT EXTRACT(EPOCH FROM NOW()),
        updatedAt BIGINT DEFAULT EXTRACT(EPOCH FROM NOW())
      )
    `);

    // Create trades table
    await client.query(`
      CREATE TABLE IF NOT EXISTS trades (
        tradeId TEXT PRIMARY KEY,
        sellerId TEXT NOT NULL,
        buyerId TEXT NOT NULL,
        amount REAL NOT NULL,
        pricePerUnit REAL NOT NULL,
        totalPrice REAL NOT NULL,
        status TEXT DEFAULT 'pending',
        hederaTransactionId TEXT,
        timestamp BIGINT DEFAULT EXTRACT(EPOCH FROM NOW()),
        FOREIGN KEY (sellerId) REFERENCES factories(factoryId),
        FOREIGN KEY (buyerId) REFERENCES factories(factoryId)
      )
    `);

    // Create transaction history table
    await client.query(`
      CREATE TABLE IF NOT EXISTS transaction_history (
        id SERIAL PRIMARY KEY,
        factoryId TEXT NOT NULL,
        transactionType TEXT NOT NULL,
        amount REAL NOT NULL,
        relatedFactoryId TEXT,
        hederaTransactionId TEXT,
        timestamp BIGINT DEFAULT EXTRACT(EPOCH FROM NOW()),
        FOREIGN KEY (factoryId) REFERENCES factories(factoryId)
      )
    `);

    console.log('✓ Database initialized');
  } finally {
    client.release();
  }
}

/**
 * Get database connection from pool
 */
function getDatabase() {
  return pool;
}

/**
 * Execute a database query
 */
async function dbRun(db, query, params = []) {
  const result = await db.query(query, params);
  return result;
}

/**
 * Get a single row from database
 */
async function dbGet(db, query, params = []) {
  const result = await db.query(query, params);
  return result.rows[0];
}

/**
 * Get all rows from database
 */
async function dbAll(db, query, params = []) {
  const result = await db.query(query, params);
  return result.rows;
}

/**
 * Close database connection (for pool, this is not typically needed)
 * Note: With connection pooling, individual connections are managed automatically.
 * Call pool.end() only when shutting down the entire application.
 * This function is kept for API compatibility with the previous SQLite implementation.
 */
async function closeDatabase(db) {
  // With connection pool, we typically don't close it
  // This is here for API compatibility
  return Promise.resolve();
}

module.exports = {
  initDatabase,
  getDatabase,
  dbRun,
  dbGet,
  dbAll,
  closeDatabase
};
