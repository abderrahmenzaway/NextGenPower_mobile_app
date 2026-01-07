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
  TokenId,
  AccountBalanceQuery,
  AccountRecordsQuery
} = require("@hashgraph/sdk");
const axios = require('axios');
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

  // Parse private key
  const privateKey = PrivateKey.fromString(myPrivateKey);

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

/**
 * Get treasury account transactions from Hedera Mirror Node API
 * Fetches transactions matching HashScan operations view:
 * - Account created (CRYPTOCREATEACCOUNT)
 * - Token transfer (CRYPTOTRANSFER with token transfers)
 * - Token association (TOKENASSOCIATE)
 * 
 * @param {number} limit - Maximum number of transactions to retrieve (default: 20)
 * @returns {Promise<Array>} Array of transaction objects with details
 */
async function getTreasuryTransactions(limit = 20) {
  try {
    const treasuryId = process.env.TREASURY_ACCOUNT_ID || process.env.MY_ACCOUNT_ID;
    
    if (!treasuryId) {
      throw new Error('Treasury account ID not configured');
    }

    // Hedera Mirror Node REST API endpoint for testnet
    const mirrorNodeUrl = `https://testnet.mirrornode.hedera.com/api/v1/transactions`;
    
    // Query parameters for treasury account transactions
    // Fetch multiple transaction types that appear in HashScan operations
    const params = {
      'account.id': treasuryId,
      limit: limit,
      order: 'desc' // Most recent first
    };

    console.log(`Fetching transactions for treasury account: ${treasuryId}`);
    
    const response = await axios.get(mirrorNodeUrl, { params });
    
    if (!response.data || !response.data.transactions) {
      return [];
    }

    // Transform the data into a more consumable format
    const transactions = response.data.transactions.map(tx => {
      // Extract token transfers if any
      const tokenTransfers = tx.token_transfers || [];
      const tecTokenId = process.env.TEC_TOKEN_ID;
      
      // Find TEC token transfers
      const tecTransfers = tokenTransfers.filter(t => 
        tecTokenId && t.token_id === tecTokenId
      );

      // Determine transaction type, amount, and parties
      let transactionType = tx.name || 'UNKNOWN';
      let displayType = transactionType;
      let amount = 0;
      let counterParty = null;
      let initiator = null;

      // Get the initiator (payer account ID)
      if (tx.transaction_id) {
        // Transaction ID format: AccountId-ValidStartSeconds-ValidStartNanos
        const parts = tx.transaction_id.split('-');
        if (parts.length >= 1) {
          initiator = parts[0];
        }
      }

      // Classify transaction types as they appear in HashScan
      if (transactionType === 'CRYPTOCREATEACCOUNT') {
        displayType = 'ACCOUNT CREATED';
        // The initiator created a new account
        if (tx.entity_id) {
          counterParty = tx.entity_id; // The created account
        }
      } else if (transactionType === 'TOKENASSOCIATE') {
        displayType = 'TOKEN ASSOCIATION';
        // The account that got associated with the token
        if (tx.entity_id) {
          counterParty = tx.entity_id;
        }
      } else if (transactionType === 'CRYPTOTRANSFER') {
        if (tecTransfers.length > 0) {
          displayType = 'TOKEN TRANSFER';
          // Find the transfer involving treasury
          const treasuryTransfer = tecTransfers.find(t => 
            t.account === treasuryId
          );
          if (treasuryTransfer) {
            amount = Math.abs(treasuryTransfer.amount) / 100; // Convert from smallest unit (2 decimals)
            // Find counterparty
            const otherTransfer = tecTransfers.find(t => 
              t.account !== treasuryId
            );
            if (otherTransfer) {
              counterParty = otherTransfer.account;
            }
          }
        } else {
          displayType = 'TOKEN TRANSFER';
        }
      } else if (transactionType === 'TOKENMINT') {
        displayType = 'TOKEN MINT';
      } else if (transactionType === 'TOKENCREATION') {
        displayType = 'TOKEN CREATION';
      }

      return {
        transactionId: tx.transaction_id,
        consensusTimestamp: tx.consensus_timestamp,
        type: displayType,
        rawType: transactionType,
        result: tx.result,
        charged_tx_fee: tx.charged_tx_fee,
        memo: tx.memo_base64 ? Buffer.from(tx.memo_base64, 'base64').toString() : '',
        amount: amount,
        counterParty: counterParty,
        initiator: initiator, // Who initiated the transaction
        token_transfers: tecTransfers
      };
    });

    return transactions;
  } catch (error) {
    console.error('Failed to fetch treasury transactions:', error.message);
    throw new Error(`Failed to fetch transactions from Hedera Mirror Node: ${error.message}`);
  }
}

/**
 * Get the latest block information from Hedera Mirror Node API
 * 
 * @returns {Promise<Object>} Object containing block height and timestamp
 */
async function getLatestBlockInfo() {
  try {
    // Hedera Mirror Node REST API endpoint for blocks
    const mirrorNodeUrl = 'https://testnet.mirrornode.hedera.com/api/v1/blocks';
    
    // Get the latest block
    const params = {
      limit: 1,
      order: 'desc'
    };

    console.log('Fetching latest block information from Hedera testnet...');
    
    const response = await axios.get(mirrorNodeUrl, { params });
    
    if (!response.data || !response.data.blocks || response.data.blocks.length === 0) {
      throw new Error('No block data available');
    }

    const latestBlock = response.data.blocks[0];
    
    return {
      blockNumber: latestBlock.number,
      timestamp: latestBlock.timestamp.from,
      hash: latestBlock.hash,
      previousHash: latestBlock.previous_hash,
      gasUsed: latestBlock.gas_used,
      transactionCount: latestBlock.count
    };
  } catch (error) {
    console.error('Failed to fetch latest block info:', error.message);
    throw new Error(`Failed to fetch block info from Hedera Mirror Node: ${error.message}`);
  }
}

/**
 * Get treasury account balance from Hedera network
 * 
 * @returns {Promise<Object>} Object containing HBAR and TEC token balances
 */
async function getTreasuryBalance() {
  const { client } = initializeHederaClient();
  
  try {
    const treasuryId = process.env.TREASURY_ACCOUNT_ID || process.env.MY_ACCOUNT_ID;
    
    if (!treasuryId) {
      throw new Error('Treasury account ID not configured');
    }

    const query = new AccountBalanceQuery()
      .setAccountId(AccountId.fromString(treasuryId));

    const balance = await query.execute(client);
    
    const result = {
      accountId: treasuryId,
      hbarBalance: balance.hbars.toString(),
      tokens: {}
    };

    // Get TEC token balance if configured
    const tecTokenId = process.env.TEC_TOKEN_ID;
    if (tecTokenId && balance.tokens) {
      const tecBalance = balance.tokens.get(TokenId.fromString(tecTokenId));
      if (tecBalance) {
        result.tokens.TEC = tecBalance.toNumber() / 100; // Convert from smallest unit
      }
    }

    return result;
  } finally {
    client.close();
  }
}

module.exports = { 
  initializeHederaClient, 
  createFactoryAccount, 
  associateTokenWithAccount,
  transferTokensBetweenAccounts,
  mintTECTokens,
  getTreasuryTransactions,
  getLatestBlockInfo,
  getTreasuryBalance
};
