/**
 * TEC Token Initialization
 * Creates the TEC (Tunisian Energy Coin) token on Hedera
 */

const {
  TokenCreateTransaction,
  TokenType,
  TokenSupplyType,
  TokenInfoQuery
} = require("@hashgraph/sdk");
const { initializeHederaClient } = require("./hedera-client");

/**
 * Create TEC token on Hedera network
 */
async function createTECToken() {
  console.log("========================================");
  console.log("  TEC Token Creation");
  console.log("========================================");

  const { client, operatorKey, treasuryId } = initializeHederaClient();

  try {
    // Create the TEC token
    console.log("\nCreating TEC token...");
    
    const tokenCreateTx = await new TokenCreateTransaction()
      .setTokenName("Tunisian Energy Coin")
      .setTokenSymbol("TEC")
      .setTokenType(TokenType.FungibleCommon)
      .setDecimals(2) // 2 decimal places for cents
      .setInitialSupply(1000000) // 1,000,000 TEC (10,000.00 with decimals)
      .setTreasuryAccountId(treasuryId)
      .setSupplyType(TokenSupplyType.Infinite)
      .setSupplyKey(operatorKey)
      .setAdminKey(operatorKey)
      .freezeWith(client);

    // Sign the transaction
    const signedTx = await tokenCreateTx.sign(operatorKey);

    // Submit to Hedera network
    const txResponse = await signedTx.execute(client);

    // Get receipt
    const receipt = await txResponse.getReceipt(client);
    const tokenId = receipt.tokenId;

    console.log(`✓ TEC Token created successfully!`);
    console.log(`  Token ID: ${tokenId}`);
    console.log(`  Token Name: Tunisian Energy Coin`);
    console.log(`  Token Symbol: TEC`);
    console.log(`  Decimals: 2`);
    console.log(`  Initial Supply: 10,000.00 TEC`);
    console.log(`  Supply Type: Infinite`);

    // Query token info to verify
    const tokenInfo = await new TokenInfoQuery()
      .setTokenId(tokenId)
      .execute(client);

    console.log("\nToken Details:");
    console.log(`  Treasury Account: ${tokenInfo.treasuryAccountId}`);
    console.log(`  Total Supply: ${tokenInfo.totalSupply.toString()}`);
    console.log(`  Max Supply: Infinite`);

    console.log("\n========================================");
    console.log("IMPORTANT: Add this to your .env file:");
    console.log(`TEC_TOKEN_ID=${tokenId}`);
    console.log("========================================");

    console.log("\nExplorer Link:");
    console.log(`https://hashscan.io/testnet/token/${tokenId}`);

    return tokenId;

  } catch (error) {
    console.error("Error creating TEC token:", error);
    throw error;
  } finally {
    client.close();
  }
}

// Run if executed directly
if (require.main === module) {
  createTECToken()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

module.exports = { createTECToken };
