#!/usr/bin/env node
/**
 * View Database Tables
 * Displays the contents of all database tables in a formatted way
 */

const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5433,
  database: process.env.DB_NAME || 'ecoguardians',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres'
});

async function viewDatabase() {
  const client = await pool.connect().catch(err => {
    console.error('❌ Database connection failed:', err.message);
    throw err;
  });

  try {
    console.log('\n📊 DATABASE CONTENTS\n');
    console.log('='.repeat(80));

    // View Factories Table
    console.log('\n📌 FACTORIES TABLE\n');
    const factories = await client.query('SELECT * FROM factories');
    if (factories.rows.length === 0) {
      console.log('   (No factories found)');
    } else {
      console.table(factories.rows.map(f => ({
        'Factory ID': f.factoryid,
        'Name': f.name,
        'Energy Type': f.energytype,
        'Energy Balance': f.energybalance,
        'Currency Balance': f.currencybalance,
        'Daily Consumption': f.dailyconsumption,
        'Available Energy': f.availableenergy,
        'Has Password': f.passwordhash ? '✓ Yes' : '✗ No'
      })));
    }

    // View Trades Table
    console.log('\n📌 TRADES TABLE\n');
    const trades = await client.query('SELECT * FROM trades');
    if (trades.rows.length === 0) {
      console.log('   (No trades found)');
    } else {
      console.table(trades.rows.map(t => ({
        'Trade ID': t.tradeid,
        'Seller': t.sellerid,
        'Buyer': t.buyerid,
        'Amount': t.amount,
        'Price/Unit': t.priceperunit,
        'Total Price': t.totalprice,
        'Status': t.status,
        'Timestamp': new Date(t.timestamp * 1000).toLocaleString()
      })));
    }

    // View Transaction History
    console.log('\n📌 TRANSACTION HISTORY TABLE\n');
    const history = await client.query('SELECT * FROM transaction_history ORDER BY timestamp DESC LIMIT 20');
    if (history.rows.length === 0) {
      console.log('   (No transactions found)');
    } else {
      console.table(history.rows.map(h => ({
        'ID': h.id,
        'Factory ID': h.factoryid,
        'Type': h.transactiontype,
        'Amount': h.amount,
        'Related Factory': h.relatedfactoryid || '-',
        'Timestamp': new Date(h.timestamp * 1000).toLocaleString()
      })));
    }

    // Show Summary
    console.log('\n📊 SUMMARY\n');
    console.log(`   Total Factories: ${factories.rows.length}`);
    console.log(`   Total Trades: ${trades.rows.length}`);
    console.log(`   Total Transactions: ${(await client.query('SELECT COUNT(*) FROM transaction_history')).rows[0].count}`);

    console.log('\n' + '='.repeat(80) + '\n');

  } catch (error) {
    console.error('❌ Error reading database:', error.message);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

// Run
viewDatabase()
  .then(() => {
    console.log('✅ Database view complete');
    process.exit(0);
  })
  .catch(error => {
    console.error('\n❌ Failed to view database');
    process.exit(1);
  });
