const pool = require('../config/db');

async function isModerateurOrAdmin(req, res, next) {
  const userId = req.user.id;
  try {
    const result = await pool.query('SELECT role FROM utilisateurs WHERE id = $1', [userId]);
    if (result.rows.length === 0) {
      return res.status(403).json({ message: 'Accès non autorisé' });
    }
    const role = result.rows[0].role;
    if (role !== 'moderateur' && role !== 'admin') {
      return res.status(403).json({ message: 'Accès réservé aux modérateurs et administrateurs' });
    }
    next();
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

module.exports = { isModerateurOrAdmin };