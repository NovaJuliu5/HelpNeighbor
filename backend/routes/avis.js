const express = require('express');
const pool = require('../config/db');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

router.get('/', authenticateToken, async (req, res) => {
  const { cible_id, cible_type, service_id } = req.query;
  try {
    let query = `
      SELECT a.id, a.commentaire, a.signalement, a.verifie_par_admin,
             a.created_at,
             an.note_globale, an.note_qualite, an.note_ponctualite,
             an.note_communication, an.note_prix,
             u.id as auteur_id, COALESCE(p.nom, '') as auteur_nom, COALESCE(p.prenom, '') as auteur_prenom
      FROM avis a
      JOIN avis_notes an ON a.id = an.avis_id
      JOIN utilisateurs u ON a.auteur_id = u.id
      LEFT JOIN profils p ON u.id = p.utilisateur_id
      WHERE 1=1
    `;
    const params = [];
    if (cible_id) {
      params.push(cible_id);
      query += ` AND a.cible_id = $${params.length}`;
    }
    if (cible_type) {
      params.push(cible_type);
      query += ` AND a.cible_type = $${params.length}`;
    }
    if (service_id) {
      params.push(service_id);
      query += ` AND a.service_id = $${params.length}`;
    }
    query += ` ORDER BY a.created_at DESC LIMIT 20`;
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post('/', authenticateToken, async (req, res) => {
  const { cible_id, cible_type, service_id, demande_id, commentaire,
          note_globale, note_qualite, note_ponctualite, note_communication, note_prix } = req.body;
  const auteur_id = req.user.id;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const checkQuery = `
      SELECT id FROM avis
      WHERE auteur_id = $1 AND cible_id = $2 AND (service_id IS NULL OR service_id = $3)
    `;
    const check = await client.query(checkQuery, [auteur_id, cible_id, service_id || null]);
    if (check.rows.length > 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ message: 'Vous avez déjà laissé un avis pour cette cible.' });
    }

    const avisResult = await client.query(
      `INSERT INTO avis (auteur_id, cible_id, cible_type, service_id, demande_id, commentaire)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
      [auteur_id, cible_id, cible_type, service_id || null, demande_id || null, commentaire || null]
    );
    const avisId = avisResult.rows[0].id;

    await client.query(
      `INSERT INTO avis_notes (avis_id, note_globale, note_qualite, note_ponctualite, note_communication, note_prix)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [avisId, note_globale, note_qualite || null, note_ponctualite || null, note_communication || null, note_prix || null]
    );

    if (cible_type === 'utilisateur') {
      const stats = await client.query(`
        SELECT
          COALESCE(AVG(an.note_globale), 0) as moyenne,
          COUNT(*) as nb_avis
        FROM avis a
        JOIN avis_notes an ON a.id = an.avis_id
        WHERE a.cible_id = $1 AND a.cible_type = 'utilisateur'
      `, [cible_id]);
      const moyenne = parseFloat(stats.rows[0].moyenne);
      const nbAvis = parseInt(stats.rows[0].nb_avis);

      await client.query(`
        INSERT INTO statistiques_utilisateurs (utilisateur_id, notation_moyenne, nombre_avis, updated_at)
        VALUES ($1, $2, $3, NOW())
        ON CONFLICT (utilisateur_id) DO UPDATE SET
          notation_moyenne = EXCLUDED.notation_moyenne,
          nombre_avis = EXCLUDED.nombre_avis,
          updated_at = NOW()
      `, [cible_id, moyenne, nbAvis]);
    }

    await client.query('COMMIT');
    res.json({ message: 'Avis publié avec succès', avis_id: avisId });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ message: err.message });
  } finally {
    client.release();
  }
});

router.get('/current', authenticateToken, async (req, res) => {
  const { cible_id, service_id } = req.query;
  const auteur_id = req.user.id;
  if (!cible_id) return res.status(400).json({ message: 'cible_id requis' });
  try {
    let query = `
      SELECT a.id, a.commentaire, a.cible_id, a.service_id, a.demande_id,
             an.note_globale, an.note_qualite, an.note_ponctualite,
             an.note_communication, an.note_prix
      FROM avis a
      JOIN avis_notes an ON a.id = an.avis_id
      WHERE a.auteur_id = $1 AND a.cible_id = $2
    `;
    const params = [auteur_id, cible_id];
    if (service_id) {
      query += ` AND a.service_id = $3`;
      params.push(service_id);
    } else {
      query += ` AND a.service_id IS NULL`;
    }
    const result = await pool.query(query, params);
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Aucun avis trouvé' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(`
      SELECT a.id, a.commentaire, a.cible_id, a.service_id, a.demande_id,
             an.note_globale, an.note_qualite, an.note_ponctualite,
             an.note_communication, an.note_prix
      FROM avis a
      JOIN avis_notes an ON a.id = an.avis_id
      WHERE a.id = $1
    `, [id]);
    if (result.rows.length === 0) return res.status(404).json({ message: 'Avis non trouvé' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.put('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { commentaire, note_globale, note_qualite, note_ponctualite, note_communication, note_prix } = req.body;
  const auteur_id = req.user.id;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const check = await client.query('SELECT auteur_id FROM avis WHERE id = $1', [id]);
    if (check.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ message: 'Avis non trouvé' });
    }
    if (check.rows[0].auteur_id !== auteur_id) {
      await client.query('ROLLBACK');
      return res.status(403).json({ message: 'Action non autorisée' });
    }

    await client.query('UPDATE avis SET commentaire = $1 WHERE id = $2', [commentaire || null, id]);
    await client.query(
      `UPDATE avis_notes SET
        note_globale = $1,
        note_qualite = $2,
        note_ponctualite = $3,
        note_communication = $4,
        note_prix = $5
       WHERE avis_id = $6`,
      [note_globale, note_qualite || null, note_ponctualite || null, note_communication || null, note_prix || null, id]
    );

    const avisData = await client.query('SELECT cible_id, service_id FROM avis WHERE id = $1', [id]);
    if (!avisData.rows[0].service_id) {
      const cibleId = avisData.rows[0].cible_id;
      const stats = await client.query(`
        SELECT
          COALESCE(AVG(an.note_globale), 0) as moyenne,
          COUNT(*) as nb_avis
        FROM avis a
        JOIN avis_notes an ON a.id = an.avis_id
        WHERE a.cible_id = $1 AND a.cible_type = 'utilisateur'
      `, [cibleId]);
      const moyenne = parseFloat(stats.rows[0].moyenne);
      const nbAvis = parseInt(stats.rows[0].nb_avis);

      await client.query(`
        INSERT INTO statistiques_utilisateurs (utilisateur_id, notation_moyenne, nombre_avis, updated_at)
        VALUES ($1, $2, $3, NOW())
        ON CONFLICT (utilisateur_id) DO UPDATE SET
          notation_moyenne = EXCLUDED.notation_moyenne,
          nombre_avis = EXCLUDED.nombre_avis,
          updated_at = NOW()
      `, [cibleId, moyenne, nbAvis]);
    }

    await client.query('COMMIT');
    res.json({ message: 'Avis mis à jour avec succès' });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ message: err.message });
  } finally {
    client.release();
  }
});

module.exports = router;