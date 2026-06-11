const pool = require('../config/db');

async function createNotification(utilisateurId, type, titre, message, donnees = null, actionUrl = null) {
  await pool.query(
    `INSERT INTO notifications (utilisateur_id, type, titre, message, donnees, action_url)
     VALUES ($1, $2, $3, $4, $5, $6)`,
    [utilisateurId, type, titre, message, donnees, actionUrl]
  );
}

module.exports = { createNotification };