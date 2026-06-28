const express = require('express');
const pool = require('../config/db');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

router.get('/proches', authenticateToken, async (req, res) => {
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
      COALESCE(sl.adresse_service, a.adresse, a.ville) as adresse,
      COALESCE(AVG(an.note_globale), 0)::float as note_moyenne,
      COUNT(DISTINCT a.id)::int as nb_avis,
      p.photo_url
    FROM services s
    LEFT JOIN categories c ON s.categorie_id = c.id
    LEFT JOIN profils p ON s.utilisateur_id = p.utilisateur_id
    LEFT JOIN services_prix sp ON s.id = sp.service_id
    LEFT JOIN services_localisation sl ON s.id = sl.service_id
    LEFT JOIN adresses a ON s.utilisateur_id = a.utilisateur_id AND a.est_principale = true
    LEFT JOIN avis av ON s.id = av.service_id
    LEFT JOIN avis_notes an ON av.id = an.avis_id
    WHERE s.disponible = true
    GROUP BY s.id, c.nom, p.nom, p.prenom, sp.prix_fixe, p.photo_url, sl.adresse_service, a.adresse, a.ville
    LIMIT 20
  `);
  console.log(" [GET /services/proches] Services retournés :",
    result.rows.map(r => ({ id: r.id, titre: r.titre, adresse: r.adresse }))
  );
  res.json(result.rows);
});

router.post('/', authenticateToken, async (req, res) => {
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

router.get('/recherche', authenticateToken, async (req, res) => {
  const { q } = req.query;
  const result = await pool.query(`
    SELECT s.id, s.titre, s.description, COALESCE(sp.prix_fixe, 0)::float as prix,
            COALESCE(c.nom, 'Sans catégorie') as categorie_nom,
            s.utilisateur_id,
            COALESCE(p.nom, '') as nom,
            COALESCE(p.prenom, '') as prenom,
            p.photo_url,
            COALESCE(sl.adresse_service, a.adresse, a.ville) as adresse
     FROM services s
     LEFT JOIN categories c ON s.categorie_id = c.id
     LEFT JOIN services_prix sp ON s.id = sp.service_id
     LEFT JOIN profils p ON s.utilisateur_id = p.utilisateur_id
     LEFT JOIN services_localisation sl ON s.id = sl.service_id
     LEFT JOIN adresses a ON s.utilisateur_id = a.utilisateur_id AND a.est_principale = true
     WHERE (s.titre ILIKE $1 OR s.description ILIKE $1) AND s.disponible = true
  `, [`%${q}%`]);
  console.log(" [GET /services/recherche] Services trouvés :",
    result.rows.map(r => ({ id: r.id, titre: r.titre, adresse: r.adresse }))
  );
  res.json(result.rows);
});

router.get('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(`
      SELECT s.id, s.titre, s.description, COALESCE(sp.prix_fixe, 0)::float as prix,
             COALESCE(c.nom, 'Sans catégorie') as categorie_nom,
             s.utilisateur_id,
             COALESCE(p.nom, '') as nom,
             COALESCE(p.prenom, '') as prenom,
             COALESCE(sl.adresse_service, a.adresse, a.ville) as adresse,
             COALESCE(AVG(an.note_globale), 0)::float as note_moyenne,
             COUNT(DISTINCT a.id)::int as nb_avis,
             p.photo_url
      FROM services s
      LEFT JOIN categories c ON s.categorie_id = c.id
      LEFT JOIN profils p ON s.utilisateur_id = p.utilisateur_id
      LEFT JOIN services_prix sp ON s.id = sp.service_id
      LEFT JOIN services_localisation sl ON s.id = sl.service_id
      LEFT JOIN adresses a ON s.utilisateur_id = a.utilisateur_id AND a.est_principale = true
      LEFT JOIN avis av ON s.id = av.service_id
      LEFT JOIN avis_notes an ON av.id = an.avis_id
      WHERE s.id = $1
      GROUP BY s.id, c.nom, p.nom, p.prenom, sp.prix_fixe, p.photo_url, sl.adresse_service, a.adresse, a.ville
    `, [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Service non trouvé' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;