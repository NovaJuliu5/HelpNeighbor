const express = require('express');
const pool = require('../config/db');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

router.get('/', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { limit = 50, offset = 0 } = req.query;
  try {
    const result = await pool.query(
      `SELECT id, type, titre, message, donnees, est_lue, created_at, action_url
       FROM notifications
       WHERE utilisateur_id = $1
       ORDER BY created_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.put('/:id/lire', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;
  try {
    await pool.query(
      `UPDATE notifications SET est_lue = true, lue_le = NOW()
       WHERE id = $1 AND utilisateur_id = $2`,
      [id, userId]
    );
    res.json({ message: 'Notification marquée comme lue' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.put('/lire-tout', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  try {
    await pool.query(
      `UPDATE notifications SET est_lue = true, lue_le = NOW()
       WHERE utilisateur_id = $1 AND est_lue = false`,
      [userId]
    );
    res.json({ message: 'Toutes les notifications marquées comme lues' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;