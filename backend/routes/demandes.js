const express = require('express');
const pool = require('../config/db');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

router.get('/proches', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const result = await pool.query(`
    SELECT d.id, d.titre, d.description, d.prix, ds.statut, d.created_at,
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
    WHERE ds.statut = 'ouverte' OR (d.utilisateur_id = $1 AND ds.statut = 'fermee')
    ORDER BY d.created_at DESC
    LIMIT 20
  `, [userId]);
  res.json(result.rows);
});

router.post('/', authenticateToken, async (req, res) => {
  const { titre, description, categorie_nom, prix } = req.body;
  const userId = req.user.id;

  const catResult = await pool.query('SELECT id FROM categories WHERE nom = $1', [categorie_nom]);
  if (catResult.rows.length === 0) {
    return res.status(400).json({ message: 'Catégorie invalide' });
  }
  const categorieId = catResult.rows[0].id;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await client.query(
      'INSERT INTO demandes (utilisateur_id, categorie_id, titre, description, prix) VALUES ($1, $2, $3, $4, $5) RETURNING id',
      [userId, categorieId, titre, description, prix || 0]
    );
    const newId = result.rows[0].id;
    await client.query(
      'INSERT INTO demandes_statuts (demande_id, statut) VALUES ($1, $2)',
      [newId, 'ouverte']
    );
    await client.query('COMMIT');

    const newDemande = await client.query(`
      SELECT d.id, d.titre, d.description, d.prix, ds.statut, d.created_at,
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
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ message: err.message });
  } finally {
    client.release();
  }
});

router.get('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(`
      SELECT d.id, d.titre, d.description, d.prix, ds.statut, d.created_at,
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
  const { titre, description, prix } = req.body;
  const userId = req.user.id;
  try {
    const check = await pool.query('SELECT utilisateur_id FROM demandes WHERE id = $1', [id]);
    if (check.rows.length === 0) return res.status(404).json({ message: 'Demande non trouvée' });
    if (check.rows[0].utilisateur_id !== userId) {
      return res.status(403).json({ message: 'Action non autorisée' });
    }
    await pool.query('UPDATE demandes SET titre = $1, description = $2, prix = $3 WHERE id = $4', [titre, description, prix, id]);
    const updated = await pool.query(`
      SELECT d.id, d.titre, d.description, d.prix, ds.statut, d.created_at,
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

router.put('/:id/statut', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { statut } = req.body;
  const userId = req.user.id;

  if (!['ouverte', 'fermee'].includes(statut)) {
    return res.status(400).json({ message: 'Statut invalide' });
  }

  try {
    const check = await pool.query('SELECT utilisateur_id FROM demandes WHERE id = $1', [id]);
    if (check.rows.length === 0) {
      return res.status(404).json({ message: 'Demande non trouvée' });
    }
    if (check.rows[0].utilisateur_id !== userId) {
      return res.status(403).json({ message: 'Action non autorisée' });
    }

    const updateResult = await pool.query(
      `UPDATE demandes_statuts SET statut = $1, updated_at = NOW() WHERE demande_id = $2 RETURNING id`,
      [statut, id]
    );
    if (updateResult.rows.length === 0) {
      await pool.query(
        `INSERT INTO demandes_statuts (demande_id, statut) VALUES ($1, $2)`,
        [id, statut]
      );
    }

    res.json({ message: 'Statut mis à jour', statut });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;