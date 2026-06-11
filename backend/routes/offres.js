const express = require('express');
const pool = require('../config/db');
const { authenticateToken } = require('../middleware/auth');
const { createNotification } = require('../utils/notifications');

const router = express.Router();

router.post('/', authenticateToken, async (req, res) => {
  const { demande_id, prestataire_id, message, prix_propose, delai_propose } = req.body;

  const demandeCheck = await pool.query(`
    SELECT d.id, ds.statut
    FROM demandes d
    JOIN demandes_statuts ds ON d.id = ds.demande_id
    WHERE d.id = $1
  `, [demande_id]);
  if (demandeCheck.rows.length === 0) return res.status(404).json({ message: 'Demande non trouvée' });
  if (demandeCheck.rows[0].statut !== 'ouverte') {
    return res.status(400).json({ message: 'Cette demande n\'est plus ouverte' });
  }

  const existingActiveOffer = await pool.query(`
    SELECT o.id FROM offres o
    JOIN offres_statuts os ON o.id = os.offre_id
    WHERE o.demande_id = $1 AND o.prestataire_id = $2 AND os.statut = 'en_attente'
  `, [demande_id, prestataire_id]);
  if (existingActiveOffer.rows.length > 0) {
    return res.status(400).json({ message: 'Vous avez déjà une offre en attente pour cette demande.' });
  }

  const result = await pool.query(
    `INSERT INTO offres (demande_id, prestataire_id, message) VALUES ($1, $2, $3) RETURNING id`,
    [demande_id, prestataire_id, message]
  );
  const offreId = result.rows[0].id;
  if (prix_propose) {
    await pool.query(
      'INSERT INTO offres_prix (offre_id, prix_propose, delai_propose) VALUES ($1, $2, $3)',
      [offreId, prix_propose, delai_propose]
    );
  }
  await pool.query(
    'INSERT INTO offres_statuts (offre_id, statut) VALUES ($1, $2)',
    [offreId, 'en_attente']
  );

  const demandeOwner = await pool.query('SELECT utilisateur_id FROM demandes WHERE id = $1', [demande_id]);
  const prestataireInfo = await pool.query('SELECT prenom, nom, photo_url FROM profils WHERE utilisateur_id = $1', [prestataire_id]);
  const prestataireNom = `${prestataireInfo.rows[0].prenom} ${prestataireInfo.rows[0].nom}`;
  await createNotification(
    demandeOwner.rows[0].utilisateur_id,
    'offre_recue',
    'Nouvelle offre',
    `${prestataireNom} a fait une offre sur votre demande.`,
    { offre_id: offreId },
    `/demande/${demande_id}`
  );

  res.json({ id: offreId, message: 'Offre créée avec succès' });
});

router.get('/demande/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(`
      SELECT o.id, o.demande_id, o.prestataire_id, o.message, o.created_at,
             os.statut,
             op.prix_propose, op.delai_propose,
             p.nom, p.prenom, p.photo_url
      FROM offres o
      LEFT JOIN offres_statuts os ON o.id = os.offre_id
      LEFT JOIN offres_prix op ON o.id = op.offre_id
      LEFT JOIN profils p ON o.prestataire_id = p.utilisateur_id
      WHERE o.demande_id = $1
      ORDER BY o.created_at DESC
    `, [id]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.put('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { statut } = req.body;
  const userId = req.user.id;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const check = await client.query(`
      SELECT d.utilisateur_id, d.id as demande_id
      FROM offres o
      JOIN demandes d ON o.demande_id = d.id
      WHERE o.id = $1
    `, [id]);
    if (check.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ message: 'Offre non trouvée' });
    }
    if (check.rows[0].utilisateur_id !== userId) {
      await client.query('ROLLBACK');
      return res.status(403).json({ message: 'Action non autorisée' });
    }
    const demandeId = check.rows[0].demande_id;

    await client.query(
      'UPDATE offres_statuts SET statut = $1 WHERE offre_id = $2',
      [statut, id]
    );

    if (statut === 'acceptee') {
      await client.query(
        'INSERT INTO demandes_statuts (demande_id, statut) VALUES ($1, $2)',
        [demandeId, 'en_cours']
      );
      await client.query(`
        UPDATE offres_statuts
        SET statut = 'refusee'
        WHERE offre_id IN (
          SELECT id FROM offres WHERE demande_id = $1
        ) AND offre_id != $2
      `, [demandeId, id]);

      const prestataireIdResult = await client.query('SELECT prestataire_id FROM offres WHERE id = $1', [id]);
      const prestataireId = prestataireIdResult.rows[0].prestataire_id;
      await createNotification(
        prestataireId,
        'offre_acceptee',
        'Offre acceptée',
        `Votre offre a été acceptée pour la demande.`,
        { offre_id: id },
        `/demande/${demandeId}`
      );
    } else if (statut === 'refusee') {
      const prestataireIdResult = await client.query('SELECT prestataire_id FROM offres WHERE id = $1', [id]);
      const prestataireId = prestataireIdResult.rows[0].prestataire_id;
      await createNotification(
        prestataireId,
        'offre_refusee',
        'Offre refusée',
        `Votre offre a été refusée pour la demande.`,
        { offre_id: id },
        `/demande/${demandeId}`
      );
    }

    await client.query('COMMIT');
    res.json({ message: `Offre ${statut === 'acceptee' ? 'acceptée' : 'refusée'} avec succès` });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ message: err.message });
  } finally {
    client.release();
  }
});

module.exports = router;