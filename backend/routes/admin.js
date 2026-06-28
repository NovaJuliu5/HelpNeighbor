const express = require('express');
const pool = require('../config/db');
const { authenticateToken } = require('../middleware/auth');
const { isAdmin } = require('../middleware/admin');
const { isModerateurOrAdmin } = require('../middleware/moderateur');
const { validateUuidParam } = require('../middleware/uuid');

const router = express.Router();

// Liste de tous les utilisateurs (modérateur ou admin)
router.get('/utilisateurs', authenticateToken, isModerateurOrAdmin, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT u.id, u.email, u.telephone, u.created_at, u.role,
             p.nom, p.prenom,
             (SELECT COUNT(*) FROM services WHERE utilisateur_id = u.id AND deleted_at IS NULL) as nb_services,
             (SELECT COUNT(*) FROM demandes WHERE utilisateur_id = u.id) as nb_demandes
      FROM utilisateurs u
      LEFT JOIN profils p ON u.id = p.utilisateur_id
      WHERE u.deleted_at IS NULL
      ORDER BY u.created_at DESC
    `);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Changer le rôle d'un utilisateur (seul l'admin peut changer en admin)
router.put('/utilisateurs/:id/role', authenticateToken, isAdmin, validateUuidParam('id'), async (req, res) => {
  const { id } = req.params;
  const { role } = req.body;
  if (!['user', 'moderateur', 'admin'].includes(role)) {
    return res.status(400).json({ message: 'Rôle invalide' });
  }
  try {
    // Vérifier que la cible n'est pas un admin si on veut le rétrograder
    if (role !== 'admin') {
      const target = await pool.query('SELECT role FROM utilisateurs WHERE id = $1', [id]);
      if (target.rows.length > 0 && target.rows[0].role === 'admin') {
        return res.status(400).json({ message: 'Impossible de rétrograder un administrateur.' });
      }
    }
    await pool.query('UPDATE utilisateurs SET role = $1 WHERE id = $2', [role, id]);
    res.json({ message: `Rôle mis à jour : ${role}` });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Supprimer un utilisateur (soft delete) - accessible modérateur/admin, mais interdit pour un admin
router.delete('/utilisateurs/:id', authenticateToken, isModerateurOrAdmin, validateUuidParam('id'), async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  console.log(` Demande de suppression de l'utilisateur ${id} par ${userId}`);

  // Empêcher l'auto-suppression
  if (id === userId) {
    console.log(' Tentative d\'auto-suppression');
    return res.status(400).json({ message: 'Vous ne pouvez pas vous supprimer vous-même.' });
  }

  try {
    // Vérifier que l'utilisateur existe et récupérer son rôle
    const check = await pool.query('SELECT id, role FROM utilisateurs WHERE id = $1', [id]);
    if (check.rows.length === 0) {
      console.log(` Utilisateur ${id} non trouvé`);
      return res.status(404).json({ message: 'Utilisateur non trouvé' });
    }

    // Interdire la suppression d'un admin
    if (check.rows[0].role === 'admin') {
      console.log(` Tentative de suppression d'un admin (${id})`);
      return res.status(403).json({ message: 'Impossible de supprimer un administrateur.' });
    }

    // Soft delete : mettre deleted_at à NOW()
    const updateResult = await pool.query(
      'UPDATE utilisateurs SET deleted_at = NOW() WHERE id = $1 RETURNING id',
      [id]
    );
    if (updateResult.rows.length === 0) {
      console.log(` Échec de la mise à jour pour ${id}`);
      return res.status(500).json({ message: 'Erreur lors de la suppression' });
    }

    console.log(` Utilisateur ${id} désactivé (soft delete)`);
    res.json({ message: 'Utilisateur désactivé avec succès' });
  } catch (err) {
    console.error(` Erreur lors de la suppression de ${id}:`, err);
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;