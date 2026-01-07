const {
	Hbar,
	Client,
	TokenCreateTransaction,
	TokenType,
	TokenSupplyType,
	PrivateKey,
	TokenMintTransaction,
	TransferTransaction
  } = require("@hashgraph/sdk");
  
  require("dotenv").config();
  
  let aliceId = process.env.MY_ACCOUNT_ID;
  let tokenId;
  let supplyKey;
  let treasuryId;
  const client = Client.forTestnet();
  const { Pool } = require('pg');
  
  async function environmentSetup() {
	const myAccountId = process.env.MY_ACCOUNT_ID;
	const myPrivateKey = process.env.MY_PRIVATE_KEY;
  
	// Check if required environment variables are present
	if (!myAccountId || !myPrivateKey) {
	  throw new Error(
		"Environment variables MY_ACCOUNT_ID and MY_PRIVATE_KEY must be present"
	  );
	}
  
	// Initialize keys and set the operator
	supplyKey = PrivateKey.fromString(myPrivateKey); // Use fromString for string input
	treasuryId = myAccountId;
  
	// Set up the Hedera client
	client.setOperator(myAccountId, myPrivateKey);
	client.setDefaultMaxTransactionFee(new Hbar(100));
	client.setDefaultMaxQueryPayment(new Hbar(50));
	console.log("Client setup complete.");
  
	// Create the NFT token
	const nftCreate = await new TokenCreateTransaction()
	  .setTokenName("ECoin")
	  .setTokenSymbol("EC")
	  .setTokenType(TokenType.FungibleCommon)
	  .setDecimals(2)
	  .setInitialSupply(100000)
	  .setTreasuryAccountId(treasuryId)
	  .setSupplyType(TokenSupplyType.Infinite)
	  .setSupplyKey(supplyKey)
	  .freezeWith(client);
  
	// Sign the transaction with the treasury key
	const nftCreateTxSign = await nftCreate.sign(PrivateKey.fromString(myPrivateKey));
  
	// Submit the transaction to the Hedera network
	const nftCreateSubmit = await nftCreateTxSign.execute(client);
  
	// Get the transaction receipt
	const nftCreateRx = await nftCreateSubmit.getReceipt(client);
  
	// Get the token ID
	tokenId = nftCreateRx.tokenId;
  
	// Log the token ID
	console.log("Created a ECoin with Token ID: " + tokenId);
  
	// Set interval to call the solve function every 60 seconds
	setInterval(() => solve(), 60 * 1000);
  }
  
  async function solve() {
	if (!tokenId || !supplyKey) return;
  
	const pool = new Pool({
	  host: process.env.DB_HOST || 'localhost',
	  port: process.env.DB_PORT || 5432,
	  database: process.env.DB_NAME || 'ecoguardians',
	  user: process.env.DB_USER || 'postgres',
	  password: process.env.DB_PASSWORD || 'postgres'
	});
  
	const now = Math.floor(Date.now() / 1000); // Current Unix timestamp in seconds
	const oneMinuteAgo = now - 60; // Timestamp for one minute ago
  
	// Max transaction fee as a constant
	const maxTransactionFee = new Hbar(20);
  
	// IPFS content identifiers for which we will create a NFT
	const CID = [
	  Buffer.from(
		"ipfs://bafyreiao6ajgsfji6qsgbqwdtjdu5gmul7tv2v3pd6kjgcw5o65b2ogst4/metadata.json"
	  ),
	];
  
	// Fetch energy data from the database
	const result = await pool.query('SELECT * FROM energy WHERE time >= $1', [oneMinuteAgo]);
	const rows = result.rows;
  
	const amount = Number(rows.reduce((prev, row) => prev + row["mwh"], 0));
  
	// Create a token transfer transaction
	let tokenTransferTx = await new TransferTransaction()
	  .addTokenTransfer(tokenId, treasuryId, -amount * 100) // Transfer from treasury
	  .addTokenTransfer(tokenId, aliceId, amount * 100)   // Transfer to Alice
	  .freezeWith(client)
	  .sign(supplyKey);
  
	// Execute the token transfer transaction
	let tokenTransferSubmit = await tokenTransferTx.execute(client);
	let tokenTransferRx = await tokenTransferSubmit.getReceipt(client);
	console.log(`\n- Stablecoin transfer from Treasury to Person: ${tokenTransferRx.status}`);
  
	// Log the serial number and token info link
	console.log("Check this link for the token info: https://explorer.arkhia.io/testnet/token/" + tokenId);
  
	// Close the database connection
	await pool.end();
  }
  
  environmentSetup();
  