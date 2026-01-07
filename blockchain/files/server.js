const { Pool } = require('pg');
const express = require("express");
const rateLimit = require('express-rate-limit');

// PostgreSQL connection pool
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'ecoguardians',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres'
});

// Main function to add records every 10 seconds
(async function main() {

})();

const app = express();

// Rate limiting: Allow 100 requests per 15 minutes per IP
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
});

app.use(express.json());
app.use('/send', limiter); // Apply rate limiting to /send endpoint

app.post("/send", async (req, res) => {
	const data = req.body;
	console.log(data);

  try {
      // Insert a new record
      await pool.query('INSERT INTO energy (mwh, time) VALUES ($1, $2)', [data.mwh, data.currentTime]);

      console.log(`Added record: mwh=${data.mwh}, time=${data.currentTime}`);
      res.json({msq: "sent successfully"});
  } catch (err) {
    console.error('Error:', err.message);
    res.status(500).json({msq: err.message});
  }
	
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});


