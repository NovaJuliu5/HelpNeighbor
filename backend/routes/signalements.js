const express = require('express');
const pool = require('../config/db');
const { authenticateToken } = require('../middleware/auth');
const { isModerateurOrAdmin } = require('../middleware/moderateur'); // ← remplace isAdmin
const { createNotification } = require('../utils/notifications');

const router = express.Router();

// Ajouter un signalement (utilisateur)
router.post('/signalements', authenticateToken, async (req, res) => {
  const { cible_type, cible_id, motif, description } = req.body;
  const utilisateur_id = req.user.id;

  if (!['service', 'demande', 'avis'].includes(cible_type)) {
    return res.status(400).json({ message: 'Type de cible invalide' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const check = await client.query(
      `SELECT id FROM signalements WHERE utilisateur_id = $1 AND cible_type = $2 AND cible_id = $3`,
      [utilisateur_id, cible_type, cible_id]
    );
    if (check.rows.length > 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ message: 'Vous avez déjà signalé ce contenu.' });
    }

    await client.query(
      `INSERT INTO signalements (utilisateur_id, cible_type, cible_id, motif, description)
       VALUES ($1, $2, $3, $4, $5)`,
      [utilisateur_id, cible_type, cible_id, motif, description || null]
    );

    const countRes = await client.query(
      `SELECT COUNT(*) FROM signalements WHERE cible_type = $1 AND cible_id = $2`,
      [cible_type, cible_id]
    );
    const nb = parseInt(countRes.rows[0].count);

    if (nb >= 5) {
      const admins = await client.query(`SELECT id FROM utilisateurs WHERE role = 'admin'`);
      for (const admin of admins.rows) {
        await client.query(
          `INSERT INTO notifications (utilisateur_id, type, titre, message, donnees, action_url)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [
            admin.id,
            'signalement_seuil_atteint',
            '⚠️ Contenu signalé plusieurs fois',
            `Le ${cible_type} (${cible_id}) a reçu ${nb} signalements.`,
            JSON.stringify({ cible_type, cible_id, nb }),
            `/admin/signalements?type=${cible_type}&id=${cible_id}`
          ]
        );
      }

      // Masquage automatique
      if (cible_type === 'service') {
        await client.query(`UPDATE services SET supprime_le = NOW() WHERE id = $1`, [cible_id]);
      } else if (cible_type === 'demande') {
        await client.query(`UPDATE demandes SET supprime_le = NOW() WHERE id = $1`, [cible_id]);
      } else if (cible_type === 'avis') {
        await client.query(`UPDATE avis SET supprime_le = NOW() WHERE id = $1`, [cible_id]);
      }
    }

    await client.query('COMMIT');
    res.json({ message: 'Signalement enregistré', signalements_count: nb });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ message: err.message });
  } finally {
    client.release();
  }
});

// Modérateur/Admin – Liste des signalements (groupés par cible)
router.get('/admin/signalements', authenticateToken, isModerateurOrAdmin, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        s.cible_type,
        s.cible_id,
        COUNT(*) as total,
        MAX(s.created_at) as dernier_signalement,
        string_agg(DISTINCT s.motif, ', ') as motifs,
        CASE
          WHEN s.cible_type = 'service' THEN (SELECT titre FROM services WHERE id = s.cible_id)
          WHEN s.cible_type = 'demande' THEN (SELECT titre FROM demandes WHERE id = s.cible_id)
          WHEN s.cible_type = 'avis' THEN (SELECT commentaire FROM avis WHERE id = s.cible_id)
        END as titre,
        CASE
          WHEN s.cible_type = 'service' THEN (SELECT description FROM services WHERE id = s.cible_id)
          WHEN s.cible_type = 'demande' THEN (SELECT description FROM demandes WHERE id = s.cible_id)
          ELSE NULL
        END as description
      FROM signalements s
      GROUP BY s.cible_type, s.cible_id
      ORDER BY total DESC, dernier_signalement DESC
    `);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message });
  }
});

// Modérateur/Admin – Supprimer définitivement un contenu (service, demande, avis)
router.delete('/admin/contenu/:type/:id', authenticateToken, isModerateurOrAdmin, async (req, res) => {
  const { type, id } = req.params;
  let table;
  if (type === 'service') table = 'services';
  else if (type === 'demande') table = 'demandes';
  else if (type === 'avis') table = 'avis';
  else return res.status(400).json({ message: 'Type invalide' });

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(`DELETE FROM ${table} WHERE id = $1`, [id]);
    await client.query(`DELETE FROM signalements WHERE cible_type = $1 AND cible_id = $2`, [type, id]);
    await client.query('COMMIT');
    res.json({ message: 'Contenu supprimé' });
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(500).json({ message: err.message });
  } finally {
    client.release();
  }
});

module.exports = router;