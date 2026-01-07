-- PostgreSQL schema for energy trading database

-- Create factories table
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
);

-- Create trades table
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
);

-- Create transaction history table
CREATE TABLE IF NOT EXISTS transaction_history (
    id SERIAL PRIMARY KEY,
    factoryId TEXT NOT NULL,
    transactionType TEXT NOT NULL,
    amount REAL NOT NULL,
    relatedFactoryId TEXT,
    hederaTransactionId TEXT,
    timestamp BIGINT DEFAULT EXTRACT(EPOCH FROM NOW()),
    FOREIGN KEY (factoryId) REFERENCES factories(factoryId)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_trades_seller ON trades(sellerId);
CREATE INDEX IF NOT EXISTS idx_trades_buyer ON trades(buyerId);
CREATE INDEX IF NOT EXISTS idx_trades_status ON trades(status);
CREATE INDEX IF NOT EXISTS idx_transaction_history_factory ON transaction_history(factoryId);
CREATE INDEX IF NOT EXISTS idx_transaction_history_timestamp ON transaction_history(timestamp);
