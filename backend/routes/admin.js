const express = require('express');
const pool = require('../config/db');
const { authenticateToken } = require('../middleware/auth');
const { isAdmin } = require('../middleware/admin');
const { validateUuidParam } = require('../middleware/uuid');

const router = express.Router();

// Liste de tous les utilisateurs
router.get('/utilisateurs', authenticateToken, isAdmin, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT u.id, u.email, u.telephone, u.created_at, u.role,
             p.nom, p.prenom,
             (SELECT COUNT(*) FROM services WHERE utilisateur_id = u.id AND deleted_at IS NULL) as nb_services,
             (SELECT COUNT(*) FROM demandes WHERE utilisateur_id = u.id) as nb_demandes
      FROM utilisateurs u
      LEFT JOIN profils p ON u.id = p.utilisateur_id
      ORDER BY u.created_at DESC
    `);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Changer le rôle d'un utilisateur
router.put('/utilisateurs/:id/role', authenticateToken, isAdmin, validateUuidParam('id'), async (req, res) => {
  const { id } = req.params;
  const { role } = req.body;
  if (!['user', 'admin'].includes(role)) {
    return res.status(400).json({ message: 'Rôle invalide' });
  }
  try {
    await pool.query('UPDATE utilisateurs SET role = $1 WHERE id = $2', [role, id]);
    res.json({ message: 'Rôle mis à jour' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Supprimer un utilisateur (soft delete)
router.delete('/utilisateurs/:id', authenticateToken, isAdmin, validateUuidParam('id'), async (req, res) => {
  const { id } = req.params;
  try {
    await pool.query('UPDATE utilisateurs SET deleted_at = NOW() WHERE id = $1', [id]);
    res.json({ message: 'Utilisateur désactivé' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;