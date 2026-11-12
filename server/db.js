const { Pool } = require('pg');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const databaseUrl = process.env.DATABASE_URL || process.env.POSTGRES_URL || process.env.POSTGRES_URL_NON_POOLING;
const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_SECRET_KEY;
const databaseConnectionString = new URL(databaseUrl);
['sslmode', 'sslcert', 'sslkey', 'sslrootcert'].forEach((parameter) => {
  databaseConnectionString.searchParams.delete(parameter);
});

const pool = new Pool({
  connectionString: databaseConnectionString.toString(),
  ssl: { rejectUnauthorized: false },
});

const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Test connection on startup
pool.query('SELECT NOW()')
  .then(() => console.log('✅ Connected to Supabase PostgreSQL'))
  .catch(err => console.error('❌ PostgreSQL connection error:', err.message));

module.exports = { pool, supabase };
