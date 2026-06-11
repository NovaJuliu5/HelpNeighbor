const pool = require('../config/db');

async function isAdmin(req, res, next) {
  const userId = req.user.id;
  try {
    const result = await pool.query('SELECT role FROM utilisateurs WHERE id = $1', [userId]);
    if (result.rows.length === 0 || result.rows[0].role !== 'admin') {
      return res.status(403).json({ message: 'Accès réservé aux administrateurs' });
    }
    next();
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

module.exports = { isAdmin };