const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'helpneighbor_db',
  password: 'admin123',
  port: 5432,
});

module.exports = pool;