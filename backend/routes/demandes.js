const express = require('express');
const pool = require('../config/db');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

router.get('/proches', authenticateToken, async (req, res) => {
  const result = await pool.query(`
    SELECT d.id, d.titre, d.description, ds.statut, d.created_at,
           d.utilisateur_id,
           COALESCE(p.nom, '') as nom,
           COALESCE(p.prenom, '') as prenom,
           p.photo_url,
           COALESCE(dl.adresse_demande, a.adresse, a.ville) as adresse
    FROM demandes d
    LEFT JOIN demandes_statuts ds ON d.id = ds.demande_id
    LEFT JOIN profils p ON d.utilisateur_id = p.utilisateur_id
    LEFT JOIN demandes_localisation dl ON d.id = dl.demande_id
    LEFT JOIN adresses a ON d.utilisateur_id = a.utilisateur_id AND a.est_principale = true
    WHERE ds.statut = 'ouverte'
    ORDER BY d.created_at DESC
    LIMIT 20
  `);
  res.json(result.rows);
});

router.post('/', authenticateToken, async (req, res) => {
  const { titre, description, categorie_nom } = req.body;
  const userId = req.user.id;

  const catResult = await pool.query('SELECT id FROM categories WHERE nom = $1', [categorie_nom]);
  if (catResult.rows.length === 0) {
    return res.status(400).json({ message: 'Catégorie invalide' });
  }
  const categorieId = catResult.rows[0].id;

  const result = await pool.query(
    'INSERT INTO demandes (utilisateur_id, categorie_id, titre, description) VALUES ($1, $2, $3, $4) RETURNING id',
    [userId, categorieId, titre, description]
  );
  const newId = result.rows[0].id;

  await pool.query('INSERT INTO demandes_statuts (demande_id, statut) VALUES ($1, $2)', [newId, 'ouverte']);

  const newDemande = await pool.query(`
    SELECT d.id, d.titre, d.description, ds.statut, d.created_at,
           COALESCE(p.nom, '') as nom, COALESCE(p.prenom, '') as prenom,
           p.photo_url,
           COALESCE(dl.adresse_demande, a.adresse, a.ville) as adresse
    FROM demandes d
    LEFT JOIN demandes_statuts ds ON d.id = ds.demande_id
    LEFT JOIN profils p ON d.utilisateur_id = p.utilisateur_id
    LEFT JOIN demandes_localisation dl ON d.id = dl.demande_id
    LEFT JOIN adresses a ON d.utilisateur_id = a.utilisateur_id AND a.est_principale = true
    WHERE d.id = $1
  `, [newId]);

  res.json(newDemande.rows[0]);
});

router.get('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(`
      SELECT d.id, d.titre, d.description, ds.statut, d.created_at,
             d.utilisateur_id,
             COALESCE(p.nom, '') as nom,
             COALESCE(p.prenom, '') as prenom,
             p.photo_url,
             COALESCE(dl.adresse_demande, a.adresse, a.ville) as adresse
      FROM demandes d
      LEFT JOIN demandes_statuts ds ON d.id = ds.demande_id
      LEFT JOIN profils p ON d.utilisateur_id = p.utilisateur_id
      LEFT JOIN demandes_localisation dl ON d.id = dl.demande_id
      LEFT JOIN adresses a ON d.utilisateur_id = a.utilisateur_id AND a.est_principale = true
      WHERE d.id = $1
    `, [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Demande non trouvée' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.put('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { titre, description } = req.body;
  const userId = req.user.id;
  try {
    const check = await pool.query('SELECT utilisateur_id FROM demandes WHERE id = $1', [id]);
    if (check.rows.length === 0) return res.status(404).json({ message: 'Demande non trouvée' });
    if (check.rows[0].utilisateur_id !== userId) {
      return res.status(403).json({ message: 'Action non autorisée' });
    }
    await pool.query('UPDATE demandes SET titre = $1, description = $2 WHERE id = $3', [titre, description, id]);
    const updated = await pool.query(`
      SELECT d.id, d.titre, d.description, ds.statut, d.created_at,
             COALESCE(p.nom, '') as nom,
             COALESCE(p.prenom, '') as prenom,
             p.photo_url,
             COALESCE(dl.adresse_demande, a.adresse, a.ville) as adresse
      FROM demandes d
      LEFT JOIN demandes_statuts ds ON d.id = ds.demande_id
      LEFT JOIN profils p ON d.utilisateur_id = p.utilisateur_id
      LEFT JOIN demandes_localisation dl ON d.id = dl.demande_id
      LEFT JOIN adresses a ON d.utilisateur_id = a.utilisateur_id AND a.est_principale = true
      WHERE d.id = $1
    `, [id]);
    res.json(updated.rows[0]);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.delete('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;
  try {
    const check = await pool.query('SELECT utilisateur_id FROM demandes WHERE id = $1', [id]);
    if (check.rows.length === 0) return res.status(404).json({ message: 'Demande non trouvée' });
    if (check.rows[0].utilisateur_id !== userId) {
      return res.status(403).json({ message: 'Action non autorisée' });
    }
    await pool.query('DELETE FROM demandes_statuts WHERE demande_id = $1', [id]);
    await pool.query('DELETE FROM offres WHERE demande_id = $1', [id]);
    await pool.query('DELETE FROM conversations WHERE demande_id = $1', [id]);
    await pool.query('DELETE FROM demandes WHERE id = $1', [id]);
    res.json({ message: 'Demande supprimée avec succès' });
  } catch (err) {
    console.error("Erreur suppression:", err);
    res.status(500).json({ message: 'Erreur serveur lors de la suppression' });
  }
});

module.exports = router;