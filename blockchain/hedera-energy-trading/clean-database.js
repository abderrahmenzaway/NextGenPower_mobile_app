#!/usr/bin/env node
/**
 * Clean Database Tables
 * Removes all records from all tables while keeping the table structure
 */

const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5433,
  database: process.env.DB_NAME || 'ecoguardians',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres'
});

async function cleanDatabase() {
  const client = await pool.connect().catch(err => {
    console.error('❌ Database connection failed:', err.message);
    console.error('   Make sure PostgreSQL is running on port 5433');
    process.exit(1);
  });

  try {
    console.log('\n🧹 CLEANING DATABASE TABLES\n');
    console.log('='.repeat(60));

    // Delete all records from tables (in correct order due to foreign keys)
    console.log('\n📌 Cleaning transaction_history table...');
    const historyResult = await client.query('DELETE FROM transaction_history');
    console.log(`   ✓ Deleted ${historyResult.rowCount} records`);

    
    console.log('\n' + '='.repeat(60));
    console.log('✅ All tables cleaned successfully!\n');

  } catch (err) {
    console.error('\n❌ Error cleaning database:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

// Run the cleanup
cleanDatabase();
