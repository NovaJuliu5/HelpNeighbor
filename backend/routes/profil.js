const express = require('express');
const pool = require('../config/db');
const { authenticateToken } = require('../middleware/auth');
const { validateUuidParam } = require('../middleware/uuid');

const router = express.Router();

// GET /api/utilisateurs/:id
router.get('/:id', authenticateToken, validateUuidParam('id'), async (req, res) => {
  const { id } = req.params;
  const result = await pool.query(`
    SELECT u.id, u.email, u.telephone,
           p.nom, p.prenom, p.photo_url, p.bio,
           a.adresse, a.ville, a.code_postal, a.pays,
           COALESCE(s.nombre_services_realises, 0) as nb_services,
           COALESCE(s.nombre_demandes_creees, 0) as nb_demandes,
           COALESCE(s.notation_moyenne, 0) as note_moyenne
    FROM utilisateurs u
    LEFT JOIN profils p ON u.id = p.utilisateur_id
    LEFT JOIN adresses a ON u.id = a.utilisateur_id AND a.est_principale = true
    LEFT JOIN statistiques_utilisateurs s ON u.id = s.utilisateur_id
    WHERE u.id = $1
  `, [id]);
  const row = result.rows[0];
  if (!row) return res.status(404).json({ message: 'Utilisateur non trouvé' });
  res.json({
    id: row.id,
    email: row.email,
    telephone: row.telephone,
    nom: row.nom ?? '',
    prenom: row.prenom ?? '',
    photo_url: row.photo_url ?? '',
    bio: row.bio ?? '',
    adresse: row.adresse,
    ville: row.ville,
    code_postal: row.code_postal,
    pays: row.pays,
    nb_services: parseInt(row.nb_services) || 0,
    nb_demandes: parseInt(row.nb_demandes) || 0,
    note_moyenne: parseFloat(row.note_moyenne) || 0
  });
});

// PUT /api/utilisateurs/profil
router.put('/profil', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { nom, prenom, photo_url, bio, adresse, ville, code_postal, pays } = req.body;

  await pool.query(
    `UPDATE profils
     SET nom = COALESCE($1, nom),
         prenom = COALESCE($2, prenom),
         photo_url = COALESCE($3, photo_url),
         bio = COALESCE($4, bio)
     WHERE utilisateur_id = $5`,
    [nom, prenom, photo_url, bio, userId]
  );

  if (adresse) {
    const existing = await pool.query(
      `SELECT id FROM adresses WHERE utilisateur_id = $1 AND est_principale = true`,
      [userId]
    );
    if (existing.rows.length > 0) {
      await pool.query(
        `UPDATE adresses
         SET adresse = $1, ville = $2, code_postal = $3, pays = $4
         WHERE utilisateur_id = $5 AND est_principale = true`,
        [adresse, ville || null, code_postal || null, pays || 'Madagascar', userId]
      );
    } else {
      await pool.query(
        `INSERT INTO adresses (utilisateur_id, adresse, ville, code_postal, pays, est_principale)
         VALUES ($1, $2, $3, $4, $5, true)`,
        [userId, adresse, ville || null, code_postal || null, pays || 'Madagascar']
      );
    }
  }

  res.json({ message: 'Profil mis à jour' });
});

module.exports = router;