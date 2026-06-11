const express = require('express');
const pool = require('../config/db');
const { authenticateToken } = require('../middleware/auth');
const { createNotification } = require('../utils/notifications');

const router = express.Router();

router.get('/', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  try {
    const result = await pool.query(`
      SELECT
        c.id,
        c.demande_id,
        c.service_id,
        c.created_at,
        c.updated_at,
        m.contenu AS dernier_message,
        m.created_at AS derniere_activite,
        autre.id AS autre_id,
        autre.nom AS autre_nom,
        autre.prenom AS autre_prenom
      FROM conversations c
      INNER JOIN participants_conversation pc ON pc.conversation_id = c.id
      LEFT JOIN LATERAL (
        SELECT contenu, created_at
        FROM messages
        WHERE conversation_id = c.id
        ORDER BY created_at DESC
        LIMIT 1
      ) m ON true
      CROSS JOIN LATERAL (
        SELECT u.id, COALESCE(p.nom, '') as nom, COALESCE(p.prenom, '') as prenom
        FROM participants_conversation pc2
        JOIN utilisateurs u ON pc2.utilisateur_id = u.id
        LEFT JOIN profils p ON u.id = p.utilisateur_id
        WHERE pc2.conversation_id = c.id AND pc2.utilisateur_id != $1
        LIMIT 1
      ) autre
      WHERE pc.utilisateur_id = $1
      GROUP BY c.id, m.contenu, m.created_at, autre.id, autre.nom, autre.prenom
      ORDER BY m.created_at DESC NULLS LAST
    `, [userId]);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message });
  }
});

router.post('/', authenticateToken, async (req, res) => {
  const { autre_id, demande_id, service_id } = req.body;
  const userId = req.user.id;

  try {
    const existing = await pool.query(`
      SELECT c.id FROM conversations c
      JOIN participants_conversation pc1 ON c.id = pc1.conversation_id
      JOIN participants_conversation pc2 ON c.id = pc2.conversation_id
      WHERE pc1.utilisateur_id = $1 AND pc2.utilisateur_id = $2
    `, [userId, autre_id]);

    if (existing.rows.length > 0) {
      return res.json({ id: existing.rows[0].id });
    }

    await pool.query('BEGIN');
    const convResult = await pool.query(
      `INSERT INTO conversations (demande_id, service_id) VALUES ($1, $2) RETURNING id`,
      [demande_id || null, service_id || null]
    );
    const convId = convResult.rows[0].id;
    await pool.query(
      `INSERT INTO participants_conversation (conversation_id, utilisateur_id) VALUES ($1, $2), ($1, $3)`,
      [convId, userId, autre_id]
    );
    await pool.query('COMMIT');
    res.json({ id: convId });
  } catch (err) {
    await pool.query('ROLLBACK');
    res.status(500).json({ message: err.message });
  }
});

router.get('/:id/messages', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(`
      SELECT m.id, m.conversation_id, m.expediteur_id, m.contenu, m.type_message, m.media_url,
             m.est_lu, m.created_at,
             COALESCE(p.nom, '') as expediteur_nom, COALESCE(p.prenom, '') as expediteur_prenom
      FROM messages m
      LEFT JOIN profils p ON m.expediteur_id = p.utilisateur_id
      WHERE m.conversation_id = $1 AND m.est_supprime_pour_expediteur = false
      ORDER BY m.created_at ASC
    `, [id]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post('/:id/messages', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { contenu, type_message } = req.body;
  const expediteurId = req.user.id;
  try {
    const part = await pool.query(
      'SELECT 1 FROM participants_conversation WHERE conversation_id = $1 AND utilisateur_id = $2',
      [id, expediteurId]
    );
    if (part.rows.length === 0) return res.status(403).json({ message: 'Non autorisé' });
    const result = await pool.query(
      `INSERT INTO messages (conversation_id, expediteur_id, contenu, type_message)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [id, expediteurId, contenu, type_message || 'texte']
    );
    await pool.query('UPDATE conversations SET updated_at = NOW() WHERE id = $1', [id]);

    const participants = await pool.query(
      `SELECT utilisateur_id FROM participants_conversation WHERE conversation_id = $1 AND utilisateur_id != $2`,
      [id, expediteurId]
    );
    for (const p of participants.rows) {
      await createNotification(
        p.utilisateur_id,
        'nouveau_message',
        'Nouveau message',
        `Vous avez reçu un nouveau message.`,
        { conversation_id: id },
        `/discussion/${id}`
      );
    }

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.put('/:id/lire', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;
  try {
    await pool.query(
      `UPDATE messages SET est_lu = true
       WHERE conversation_id = $1 AND expediteur_id != $2 AND est_lu = false`,
      [id, userId]
    );
    res.json({ message: 'Messages marqués comme lus' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;