const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');
const { JWT_SECRET } = require('../middleware/auth');

const router = express.Router();

router.post('/connexion', async (req, res) => {
  const { email, password } = req.body;
  try {
    const result = await pool.query(
      'SELECT u.id, u.email, u.role, p.nom, p.prenom, u.mot_de_passe_hash FROM utilisateurs u LEFT JOIN profils p ON u.id = p.utilisateur_id WHERE u.email = $1',
      [email]
    );
    if (result.rows.length === 0) return res.status(401).json({ message: 'Email ou mot de passe incorrect' });
    const user = result.rows[0];
    const valid = await bcrypt.compare(password, user.mot_de_passe_hash);
    if (!valid) return res.status(401).json({ message: 'Email ou mot de passe incorrect' });
    const token = jwt.sign({ id: user.id }, JWT_SECRET, { expiresIn: '7d' });
    res.json({
      token,
      utilisateur: {
        id: user.id,
        email: user.email,
        role: user.role ?? 'user',
        nom: user.nom ?? '',
        prenom: user.prenom ?? '',
        note_moyenne: 0
      }
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post('/inscription', async (req, res) => {
  const { email, password, nom, prenom } = req.body;
  const hashed = await bcrypt.hash(password, 10);
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const userRes = await client.query(
      'INSERT INTO utilisateurs (email, mot_de_passe_hash) VALUES ($1, $2) RETURNING id',
      [email, hashed]
    );
    const userId = userRes.rows[0].id;
    await client.query(
      'INSERT INTO profils (utilisateur_id, nom, prenom) VALUES ($1, $2, $3)',
      [userId, nom, prenom]
    );
    await client.query('COMMIT');
    const token = jwt.sign({ id: userId }, JWT_SECRET, { expiresIn: '7d' });
    res.json({
      token,
      utilisateur: {
        id: userId,
        email,
        role: 'user',
        nom,
        prenom,
        note_moyenne: 0
      }
    });
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(500).json({ message: err.message });
  } finally {
    client.release();
  }
});

module.exports = router;