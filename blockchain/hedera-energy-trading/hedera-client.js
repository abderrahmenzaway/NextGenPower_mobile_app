/**
 * Hedera Client Configuration
 * Sets up the connection to Hedera Testnet for energy trading
 */

const {
  Client,
  PrivateKey,
  Hbar,
  AccountCreateTransaction,
  TokenAssociateTransaction,
  TransferTransaction,
  TokenMintTransaction,
  AccountId,
  TokenId
} = require("@hashgraph/sdk");
require("dotenv").config();

/**
 * Initialize and configure Hedera client
 * @returns {Object} Configured client and keys
 */
function initializeHederaClient() {
  const myAccountId = process.env.MY_ACCOUNT_ID;
  const myPrivateKey = process.env.MY_PRIVATE_KEY;
  const treasuryId = process.env.TREASURY_ACCOUNT_ID || myAccountId;

  // Validate environment variables
  if (!myAccountId || !myPrivateKey) {
    throw new Error(
      "Environment variables MY_ACCOUNT_ID and MY_PRIVATE_KEY must be present"
    );
  }

  // Parse private key - use ECDSA format for accounts created in Hedera portal
  const privateKey = PrivateKey.fromStringECDSA(myPrivateKey);

  // Set up the Hedera client for Testnet
  const client = Client.forTestnet();
  client.setOperator(myAccountId, privateKey);
  
  // Set default transaction and query fees
  client.setDefaultMaxTransactionFee(new Hbar(100));
  client.setDefaultMaxQueryPayment(new Hbar(50));

  console.log("✓ Hedera client initialized");
  console.log(`  Account ID: ${myAccountId}`);
  console.log(`  Network: Testnet`);

  return {
    client,
    operatorId: myAccountId,
    operatorKey: privateKey,
    treasuryId
  };
}

/**
 * Create a new Hedera account for a factory
 * @param {number} initialBalance - Initial HBAR balance for the account (default: 10 HBAR)
 * @returns {Promise<{accountId: string, privateKey: string}>} Created account info
 */
async function createFactoryAccount(initialBalance = 10) {
  const { client, operatorKey } = initializeHederaClient();
  
  try {
    // Generate new key pair for the factory account
    const newAccountPrivateKey = PrivateKey.generateED25519();
    const newAccountPublicKey = newAccountPrivateKey.publicKey;

    // Create new account
    const newAccountTx = await new AccountCreateTransaction()
      .setKey(newAccountPublicKey)
      .setInitialBalance(new Hbar(initialBalance))
      .execute(client);

    // Get the receipt
    const receipt = await newAccountTx.getReceipt(client);
    const newAccountId = receipt.accountId;

    console.log(`✓ Created Hedera account: ${newAccountId}`);

    return {
      accountId: newAccountId.toString(),
      privateKey: newAccountPrivateKey.toString()
    };
  } finally {
    client.close();
  }
}

/**
 * Associate a token with a Hedera account
 * @param {string} accountId - Account ID to associate with token
 * @param {string} accountPrivateKey - Private key of the account
 * @param {string} tokenId - Token ID to associate
 * @returns {Promise<string>} Transaction ID
 */
async function associateTokenWithAccount(accountId, accountPrivateKey, tokenId) {
  const { client } = initializeHederaClient();
  
  try {
    const privateKey = PrivateKey.fromString(accountPrivateKey);
    
    // Create token association transaction
    const associateTx = await new TokenAssociateTransaction()
      .setAccountId(AccountId.fromString(accountId))
      .setTokenIds([TokenId.fromString(tokenId)])
      .freezeWith(client);

    // Sign with the account's private key
    const signedTx = await associateTx.sign(privateKey);

    // Submit transaction
    const txResponse = await signedTx.execute(client);

    // Get receipt
    const receipt = await txResponse.getReceipt(client);

    console.log(`✓ Token ${tokenId} associated with account ${accountId}`);

    return txResponse.transactionId.toString();
  } finally {
    client.close();
  }
}

/**
 * Transfer tokens between Hedera accounts
 * @param {string} fromAccountId - Sender account ID
 * @param {string} fromAccountPrivateKey - Sender private key
 * @param {string} toAccountId - Receiver account ID
 * @param {string} tokenId - Token ID to transfer
 * @param {number} amount - Amount to transfer (in token smallest unit)
 * @returns {Promise<string>} Transaction ID
 */
async function transferTokensBetweenAccounts(fromAccountId, fromAccountPrivateKey, toAccountId, tokenId, amount) {
  const { client } = initializeHederaClient();
  
  try {
    const fromPrivateKey = PrivateKey.fromString(fromAccountPrivateKey);
    
    // Create transfer transaction
    const transferTx = await new TransferTransaction()
      .addTokenTransfer(
        TokenId.fromString(tokenId),
        AccountId.fromString(fromAccountId),
        -amount
      )
      .addTokenTransfer(
        TokenId.fromString(tokenId),
        AccountId.fromString(toAccountId),
        amount
      )
      .freezeWith(client);

    // Sign with sender's private key
    const signedTx = await transferTx.sign(fromPrivateKey);

    // Execute transaction
    const txResponse = await signedTx.execute(client);

    // Get receipt to confirm
    const receipt = await txResponse.getReceipt(client);

    console.log(`✓ Transferred ${amount} tokens from ${fromAccountId} to ${toAccountId}`);
    console.log(`  Transaction ID: ${txResponse.transactionId.toString()}`);

    return txResponse.transactionId.toString();
  } finally {
    client.close();
  }
}

/**
 * Mint TEC tokens on Hedera network
 * Increases the total supply of TEC tokens
 * 
 * @param {string} tokenId - Token ID to mint
 * @param {number} amount - Amount to mint (in token smallest unit)
 * @returns {Promise<string>} Transaction ID
 */
async function mintTECTokens(tokenId, amount) {
  const { client, operatorKey } = initializeHederaClient();
  
  try {
    if (!tokenId) {
      throw new Error('Token ID is required for minting');
    }

    if (amount <= 0) {
      throw new Error('Mint amount must be positive');
    }

    console.log(`Minting ${amount} TEC token units on Hedera...`);
    
    // Create token mint transaction
    const mintTx = await new TokenMintTransaction()
      .setTokenId(TokenId.fromString(tokenId))
      .setAmount(amount)
      .freezeWith(client);

    // Sign with supply key (operator key in this case)
    const signedTx = await mintTx.sign(operatorKey);

    // Execute transaction
    const txResponse = await signedTx.execute(client);

    // Get receipt to confirm
    const receipt = await txResponse.getReceipt(client);

    console.log(`✓ Minted ${amount} TEC tokens successfully`);
    console.log(`  Transaction ID: ${txResponse.transactionId.toString()}`);
    console.log(`  New Total Supply: ${receipt.totalSupply.toString()}`);
    console.log(`  View on HashScan: https://hashscan.io/testnet/transaction/${txResponse.transactionId.toString()}`);

    return txResponse.transactionId.toString();
  } catch (error) {
    console.error('Failed to mint TEC tokens:', error.message);
    
    // Provide more specific error messages
    if (error.message.includes('TOKEN_HAS_NO_SUPPLY_KEY')) {
      throw new Error('Token does not have a supply key configured for minting');
    }
    
    throw new Error(`Hedera token mint failed: ${error.message}`);
  } finally {
    client.close();
  }
}

module.exports = { 
  initializeHederaClient, 
  createFactoryAccount, 
  associateTokenWithAccount,
  transferTokensBetweenAccounts,
  mintTECTokens
};
