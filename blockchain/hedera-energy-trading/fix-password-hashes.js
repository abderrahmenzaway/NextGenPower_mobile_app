#!/usr/bin/env node
/**
 * Migration script to fix factories with NULL password hashes
 * 
 * This script:
 * 1. Finds all factories with NULL password hashes
 * 2. Sets a secure temporary password hash
 * 3. Provides instructions for users to reset their passwords
 * 
 * Usage: node fix-password-hashes.js
 */

const bcrypt = require('bcrypt');
const { Pool } = require('pg');

// PostgreSQL connection pool
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5433,
  database: process.env.DB_NAME || 'ecoguardians',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres'
});

/**
 * Fix password hashes for factories
 */
async function fixPasswordHashes() {
  const client = await pool.connect().catch(err => {
    console.error('❌ Database connection failed:', err.message);
    throw err;
  });

  try {
    console.log('🔍 Scanning for factories with NULL password hashes...\n');

    // Find factories with NULL password hashes
    const result = await client.query(
      'SELECT factoryId, name FROM factories WHERE passwordHash IS NULL OR passwordHash = \'\''
    );

    if (result.rows.length === 0) {
      console.log('✓ All factories have valid password hashes. No fixes needed.');
      return;
    }

    console.log(`Found ${result.rows.length} factories with missing password hashes:\n`);

    // Fix each factory
    const saltRounds = 10;
    const fixedFactories = [];

    for (const factory of result.rows) {
      try {
        // Create a temporary secure password hash
        // In production, this would be replaced by user password reset
        const tempPassword = `TempPwd_${factory.factoryId}_${Date.now()}`;
        const passwordHash = await bcrypt.hash(tempPassword, saltRounds);

        // Update database
        await client.query(
          'UPDATE factories SET passwordHash = $1 WHERE factoryId = $2',
          [passwordHash, factory.factoryId]
        );

        fixedFactories.push({
          factoryId: factory.factoryId,
          name: factory.name,
          tempPassword: tempPassword
        });

        console.log(`✓ Fixed: ${factory.factoryId} (${factory.name})`);
      } catch (error) {
        console.error(`✗ Failed to fix ${factory.factoryId}: ${error.message}`);
      }
    }

    console.log(`\n✓ Fixed ${fixedFactories.length} factories\n`);

    if (fixedFactories.length > 0) {
      console.log('⚠️  IMPORTANT: Users must reset their passwords!');
      console.log('These factories had no password hashes and temporary hashes have been set.\n');
      console.log('Generated temporary passwords (SAVE THESE):\n');

      fixedFactories.forEach(f => {
        console.log(`Factory ID: ${f.factoryId}`);
        console.log(`Name: ${f.name}`);
        console.log(`Temporary Password: ${f.tempPassword}`);
        console.log('---');
      });

      console.log('\nInstructions:');
      console.log('1. Users should log in with their factory ID and the temporary password above');
      console.log('2. After logging in, they should immediately reset their password');
      console.log('3. Share these credentials securely with the respective factory owners');
    }

  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

// Run the migration
fixPasswordHashes()
  .then(() => {
    console.log('\n✅ Migration completed successfully');
    process.exit(0);
  })
  .catch(error => {
    console.error('\n❌ Migration failed');
    process.exit(1);
  });
