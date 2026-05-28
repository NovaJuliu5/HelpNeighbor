const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'helpneighbor_db',
  password: 'admin123',
  port: 5432,
});

const JWT_SECRET = 'votre_secret_jwt';

// ---------- Authentification ----------
app.post('/api/auth/connexion', async (req, res) => {
  const { email, password } = req.body;
  try {
    const result = await pool.query(
      'SELECT u.id, u.email, p.nom, p.prenom, u.mot_de_passe_hash FROM utilisateurs u LEFT JOIN profils p ON u.id = p.utilisateur_id WHERE u.email = $1',
      [email]
    );
    if (result.rows.length === 0) return res.status(401).json({ message: 'Email ou mot de passe incorrect' });
    const user = result.rows[0];
    const valid = await bcrypt.compare(password, user.mot_de_passe_hash);
    if (!valid) return res.status(401).json({ message: 'Email ou mot de passe incorrect' });
    const token = jwt.sign({ id: user.id }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, utilisateur: { id: user.id, email: user.email, nom: user.nom ?? '', prenom: user.prenom ?? '', note_moyenne: 0 } });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.post('/api/auth/inscription', async (req, res) => {
  const { email, password, nom, prenom } = req.body;
  const hashed = await bcrypt.hash(password, 10);
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const userRes = await client.query(
      'INSERT INTO utilisateurs (email, mot_de_passe_hash) VALUES ($1, $2) RETURNING id',
      [email, hashed]
    );
    const userId = userRes.rows[0].id;
    await client.query(
      'INSERT INTO profils (utilisateur_id, nom, prenom) VALUES ($1, $2, $3)',
      [userId, nom, prenom]
    );
    await client.query('COMMIT');
    const token = jwt.sign({ id: userId }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, utilisateur: { id: userId, email, nom, prenom, note_moyenne: 0 } });
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(500).json({ message: err.message });
  } finally {
    client.release();
  }
});

// ---------- Profil ----------
app.get('/api/utilisateurs/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const result = await pool.query(`
    SELECT u.id, u.email, u.telephone,
           p.nom, p.prenom, p.photo_url, p.bio,
           (SELECT COUNT(*) FROM services WHERE utilisateur_id = u.id AND deleted_at IS NULL) as nb_services,
           (SELECT COUNT(*) FROM demandes WHERE utilisateur_id = u.id) as nb_demandes,
           COALESCE((SELECT AVG(an.note_globale) FROM avis a JOIN avis_notes an ON a.id = an.avis_id WHERE a.cible_id = u.id), 0) as note_moyenne
    FROM utilisateurs u
    LEFT JOIN profils p ON u.id = p.utilisateur_id
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
    nb_services: parseInt(row.nb_services) || 0,
    nb_demandes: parseInt(row.nb_demandes) || 0,
    note_moyenne: parseFloat(row.note_moyenne) || 0
  });
});

app.put('/api/utilisateurs/profil', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { nom, prenom, photo_url, bio } = req.body;
  await pool.query(
    'UPDATE profils SET nom = COALESCE($1, nom), prenom = COALESCE($2, prenom), photo_url = COALESCE($3, photo_url), bio = COALESCE($4, bio) WHERE utilisateur_id = $5',
    [nom, prenom, photo_url, bio, userId]
  );
  res.json({ message: 'Profil mis à jour' });
});

// ---------- Services ----------
app.get('/api/services/proches', authenticateToken, async (req, res) => {
  const { lat, lon, rayon } = req.query;
  const result = await pool.query(`
    SELECT
      s.id,
      s.titre,
      s.description,
      COALESCE(sp.prix_fixe, 0)::float as prix,
      COALESCE(c.nom, 'Sans catégorie') as categorie_nom,
      s.utilisateur_id,
      COALESCE(p.nom, '') as nom,
      COALESCE(p.prenom, '') as prenom,
      0::float as distance_km,
      COALESCE(AVG(an.note_globale), 0)::float as note_moyenne,
      COUNT(DISTINCT a.id)::int as nb_avis,
      p.photo_url
    FROM services s
    LEFT JOIN categories c ON s.categorie_id = c.id
    LEFT JOIN profils p ON s.utilisateur_id = p.utilisateur_id
    LEFT JOIN services_prix sp ON s.id = sp.service_id
    LEFT JOIN avis a ON s.id = a.service_id
    LEFT JOIN avis_notes an ON a.id = an.avis_id
    WHERE s.disponible = true
    GROUP BY s.id, c.nom, p.nom, p.prenom, sp.prix_fixe, p.photo_url
    LIMIT 20
  `);
  res.json(result.rows);
});

app.post('/api/services', authenticateToken, async (req, res) => {
  const { titre, description, categorie_id, prix } = req.body;
  const userId = req.user.id;
  const result = await pool.query(
    'INSERT INTO services (utilisateur_id, categorie_id, titre, description) VALUES ($1, $2, $3, $4) RETURNING id',
    [userId, categorie_id, titre, description]
  );
  if (prix) {
    await pool.query('INSERT INTO services_prix (service_id, prix_fixe) VALUES ($1, $2)', [result.rows[0].id, prix]);
  }
  res.json({ id: result.rows[0].id });
});

app.get('/api/services/recherche', authenticateToken, async (req, res) => {
  const { q } = req.query;
  const result = await pool.query(`
    SELECT s.id, s.titre, s.description, COALESCE(sp.prix_fixe, 0)::float as prix,
            COALESCE(c.nom, 'Sans catégorie') as categorie_nom,
            s.utilisateur_id,
            COALESCE(p.nom, '') as nom,
            COALESCE(p.prenom, '') as prenom,
            p.photo_url
     FROM services s
     LEFT JOIN categories c ON s.categorie_id = c.id
     LEFT JOIN services_prix sp ON s.id = sp.service_id
     LEFT JOIN profils p ON s.utilisateur_id = p.utilisateur_id
     WHERE (s.titre ILIKE $1 OR s.description ILIKE $1) AND s.disponible = true
  `, [`%${q}%`]);
  res.json(result.rows);
});

// ---------- Récupérer un service par son ID ----------
app.get('/api/services/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(`
      SELECT s.id, s.titre, s.description, COALESCE(sp.prix_fixe, 0)::float as prix,
             COALESCE(c.nom, 'Sans catégorie') as categorie_nom,
             s.utilisateur_id,
             COALESCE(p.nom, '') as nom,
             COALESCE(p.prenom, '') as prenom,
             0::float as distance_km,
             COALESCE(AVG(an.note_globale), 0)::float as note_moyenne,
             COUNT(DISTINCT a.id)::int as nb_avis,
             p.photo_url
      FROM services s
      LEFT JOIN categories c ON s.categorie_id = c.id
      LEFT JOIN profils p ON s.utilisateur_id = p.utilisateur_id
      LEFT JOIN services_prix sp ON s.id = sp.service_id
      LEFT JOIN avis a ON s.id = a.service_id
      LEFT JOIN avis_notes an ON a.id = an.avis_id
      WHERE s.id = $1
      GROUP BY s.id, c.nom, p.nom, p.prenom, sp.prix_fixe, p.photo_url
    `, [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Service non trouvé' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ---------- Demandes ----------
app.get('/api/demandes/proches', authenticateToken, async (req, res) => {
  const result = await pool.query(`
    SELECT d.id, d.titre, d.description, ds.statut, d.created_at,
           d.utilisateur_id,
           COALESCE(p.nom, '') as nom,
           COALESCE(p.prenom, '') as prenom,
           p.photo_url
    FROM demandes d
    LEFT JOIN demandes_statuts ds ON d.id = ds.demande_id
    LEFT JOIN profils p ON d.utilisateur_id = p.utilisateur_id
    WHERE ds.statut = 'ouverte'
    ORDER BY d.created_at DESC
    LIMIT 20
  `);
  res.json(result.rows);
});

app.post('/api/demandes', authenticateToken, async (req, res) => {
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
           p.photo_url
    FROM demandes d
    LEFT JOIN demandes_statuts ds ON d.id = ds.demande_id
    LEFT JOIN profils p ON d.utilisateur_id = p.utilisateur_id
    WHERE d.id = $1
  `, [newId]);

  res.json(newDemande.rows[0]);
});

app.get('/api/demandes/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(`
      SELECT d.id, d.titre, d.description, ds.statut, d.created_at,
             d.utilisateur_id,
             COALESCE(p.nom, '') as nom,
             COALESCE(p.prenom, '') as prenom,
             p.photo_url
      FROM demandes d
      LEFT JOIN demandes_statuts ds ON d.id = ds.demande_id
      LEFT JOIN profils p ON d.utilisateur_id = p.utilisateur_id
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

app.put('/api/demandes/:id', authenticateToken, async (req, res) => {
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
             COALESCE(p.nom, '') as nom, COALESCE(p.prenom, '') as prenom,
             p.photo_url
      FROM demandes d
      LEFT JOIN demandes_statuts ds ON d.id = ds.demande_id
      LEFT JOIN profils p ON d.utilisateur_id = p.utilisateur_id
      WHERE d.id = $1
    `, [id]);
    res.json(updated.rows[0]);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.delete('/api/demandes/:id', authenticateToken, async (req, res) => {
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

// ---------- Offres ----------
app.post('/api/offres', authenticateToken, async (req, res) => {
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

app.get('/api/demandes/:id/offres', authenticateToken, async (req, res) => {
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

app.put('/api/offres/:id', authenticateToken, async (req, res) => {
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

// ---------- Avis & notations ----------
app.get('/api/avis', authenticateToken, async (req, res) => {
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

app.post('/api/avis', authenticateToken, async (req, res) => {
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
      await client.query(`
        UPDATE statistiques_utilisateurs
        SET notation_moyenne = (
          SELECT AVG(an.note_globale) FROM avis a
          JOIN avis_notes an ON a.id = an.avis_id
          WHERE a.cible_id = $1
        ), nombre_avis = (
          SELECT COUNT(*) FROM avis WHERE cible_id = $1
        )
        WHERE utilisateur_id = $1
      `, [cible_id]);
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

// Récupérer l'avis de l'utilisateur courant pour une cible
app.get('/api/avis/current', authenticateToken, async (req, res) => {
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

// Récupérer un avis par son ID
app.get('/api/avis/:id', authenticateToken, async (req, res) => {
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

// Modifier un avis existant
app.put('/api/avis/:id', authenticateToken, async (req, res) => {
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

    // Mettre à jour la moyenne de l'utilisateur cible
    const avisData = await client.query('SELECT cible_id, service_id FROM avis WHERE id = $1', [id]);
    if (!avisData.rows[0].service_id) {
      const cibleId = avisData.rows[0].cible_id;
      await client.query(`
        UPDATE statistiques_utilisateurs
        SET notation_moyenne = (
          SELECT AVG(an.note_globale) FROM avis a
          JOIN avis_notes an ON a.id = an.avis_id
          WHERE a.cible_id = $1
        ), nombre_avis = (
          SELECT COUNT(*) FROM avis WHERE cible_id = $1
        )
        WHERE utilisateur_id = $1
      `, [cibleId]);
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

// ---------- Conversations ----------
app.get('/api/conversations', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  try {
    const result = await pool.query(`
      SELECT c.id, c.demande_id, c.service_id, c.created_at, c.updated_at,
             u2.id as autre_id, COALESCE(p.nom, '') as autre_nom, COALESCE(p.prenom, '') as autre_prenom,
             (SELECT contenu FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) as dernier_message,
             (SELECT created_at FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) as derniere_activite
      FROM conversations c
      JOIN participants_conversation pc ON c.id = pc.conversation_id
      JOIN utilisateurs u2 ON pc.utilisateur_id = u2.id
      LEFT JOIN profils p ON u2.id = p.utilisateur_id
      WHERE c.id IN (
        SELECT conversation_id FROM participants_conversation WHERE utilisateur_id = $1
      ) AND pc.utilisateur_id != $1
      ORDER BY derniere_activite DESC NULLS LAST
    `, [userId]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.post('/api/conversations', authenticateToken, async (req, res) => {
  const { autre_id, demande_id, service_id } = req.body;
  const userId = req.user.id;
  try {
    let query = `
      SELECT c.id FROM conversations c
      JOIN participants_conversation pc1 ON c.id = pc1.conversation_id
      JOIN participants_conversation pc2 ON c.id = pc2.conversation_id
      WHERE pc1.utilisateur_id = $1 AND pc2.utilisateur_id = $2
    `;
    const params = [userId, autre_id];
    if (demande_id) {
      query += ` AND c.demande_id = $3`;
      params.push(demande_id);
    } else if (service_id) {
      query += ` AND c.service_id = $3`;
      params.push(service_id);
    }
    const existing = await pool.query(query, params);
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

app.get('/api/conversations/:id/messages', authenticateToken, async (req, res) => {
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

app.post('/api/conversations/:id/messages', authenticateToken, async (req, res) => {
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

app.put('/api/conversations/:id/lire', authenticateToken, async (req, res) => {
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

// ---------- Notifications ----------
app.get('/api/notifications', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { limit = 50, offset = 0 } = req.query;
  try {
    const result = await pool.query(
      `SELECT id, type, titre, message, donnees, est_lue, created_at, action_url
       FROM notifications
       WHERE utilisateur_id = $1
       ORDER BY created_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.put('/api/notifications/:id/lire', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;
  try {
    await pool.query(
      `UPDATE notifications SET est_lue = true, lue_le = NOW()
       WHERE id = $1 AND utilisateur_id = $2`,
      [id, userId]
    );
    res.json({ message: 'Notification marquée comme lue' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.put('/api/notifications/lire-tout', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  try {
    await pool.query(
      `UPDATE notifications SET est_lue = true, lue_le = NOW()
       WHERE utilisateur_id = $1 AND est_lue = false`,
      [userId]
    );
    res.json({ message: 'Toutes les notifications marquées comme lues' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

async function createNotification(utilisateurId, type, titre, message, donnees = null, actionUrl = null) {
  await pool.query(
    `INSERT INTO notifications (utilisateur_id, type, titre, message, donnees, action_url)
     VALUES ($1, $2, $3, $4, $5, $6)`,
    [utilisateurId, type, titre, message, donnees, actionUrl]
  );
}

function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.sendStatus(401);
  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
}

const PORT = 3000;
app.listen(PORT, () => console.log(`Backend démarré sur http://localhost:${PORT}`));