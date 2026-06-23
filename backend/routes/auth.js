console.log('🟢 Chargement du fichier routes/auth.js');

const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');          // Pour générer le token de réinitialisation
const nodemailer = require('nodemailer');  // Pour l'envoi d'email
const pool = require('../config/db');
const { JWT_SECRET } = require('../middleware/auth');

const router = express.Router();

// ============================================================
// Route d'inscription
// ============================================================
router.post('/inscription', async (req, res) => {
  const { email, password, nom, prenom } = req.body;

  if (!password || password.length < 6) {
    return res.status(400).json({
      message: 'Le mot de passe doit contenir au moins 6 caractères.'
    });
  }

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
    res.json({
      token,
      utilisateur: {
        id: userId,
        email,
        role: 'user',
        nom,
        prenom,
        note_moyenne: 0
      }
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ message: err.message });
  } finally {
    client.release();
  }
});

// ============================================================
// Route de connexion
// ============================================================
router.post('/connexion', async (req, res) => {
  const { email, password } = req.body;
  try {
    const result = await pool.query(
      'SELECT u.id, u.email, u.role, p.nom, p.prenom, u.mot_de_passe_hash FROM utilisateurs u LEFT JOIN profils p ON u.id = p.utilisateur_id WHERE u.email = $1',
      [email]
    );
    if (result.rows.length === 0) {
      return res.status(401).json({ message: 'Email ou mot de passe incorrect' });
    }
    const user = result.rows[0];
    const valid = await bcrypt.compare(password, user.mot_de_passe_hash);
    if (!valid) {
      return res.status(401).json({ message: 'Email ou mot de passe incorrect' });
    }
    const token = jwt.sign({ id: user.id }, JWT_SECRET, { expiresIn: '7d' });
    res.json({
      token,
      utilisateur: {
        id: user.id,
        email: user.email,
        role: user.role ?? 'user',
        nom: user.nom ?? '',
        prenom: user.prenom ?? '',
        note_moyenne: 0
      }
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ============================================================
// Demande de réinitialisation du mot de passe (envoi d'email)
// ============================================================
router.post('/mot-de-passe-oublie', async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ message: 'Email requis' });
  }

  try {
    // Vérifier si l'utilisateur existe
    const userResult = await pool.query(
      'SELECT id FROM utilisateurs WHERE email = $1',
      [email]
    );

    // Sécurité : on répond 200 même si l'email n'existe pas
    if (userResult.rows.length === 0) {
      return res.status(200).json({ message: 'Si l\'email existe, un lien a été envoyé.' });
    }

    const userId = userResult.rows[0].id;

    // Générer un token (valable 1h)
    const token = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000);

    // Supprimer l'ancien token s'il existe, puis insérer le nouveau
    await pool.query('DELETE FROM securite_comptes WHERE utilisateur_id = $1', [userId]);
    await pool.query(
      'INSERT INTO securite_comptes (utilisateur_id, reset_password_token, reset_password_expires) VALUES ($1, $2, $3)',
      [userId, token, expiresAt]
    );

    // Envoi de l'email
    const transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: parseInt(process.env.SMTP_PORT || '587'),
      secure: false,
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
    });

    const resetLink = `${process.env.FRONTEND_URL}/reinitialiser-mot-de-passe?token=${token}`;

    await transporter.sendMail({
      from: '"Help Neighbor" <no-reply@helpneighbor.com>',
      to: email,
      subject: 'Réinitialisation de votre mot de passe',
      html: `
        <h1>Réinitialisation de mot de passe</h1>
        <p>Cliquez sur le lien ci-dessous pour réinitialiser votre mot de passe :</p>
        <a href="${resetLink}">${resetLink}</a>
        <p>Ce lien est valable 1 heure.</p>
        <p>Si vous n'avez pas demandé cette réinitialisation, ignorez cet email.</p>
      `,
    });

    res.status(200).json({ message: 'Email envoyé avec succès' });
  } catch (error) {
    console.error('Erreur demande réinitialisation:', error);
    const message = process.env.NODE_ENV === 'development'
      ? error.message
      : 'Erreur serveur';
    res.status(500).json({ message });
  }
});

// ============================================================
// RÉINITIALISATION EFFECTIVE DU MOT DE PASSE (avec token)
// ============================================================
router.post('/reinitialiser-mot-de-passe', async (req, res) => {
  const { token, nouveauMotDePasse } = req.body;

  if (!token || !nouveauMotDePasse) {
    return res.status(400).json({ message: 'Token et nouveau mot de passe requis' });
  }

  try {
    // 1. Vérifier le token et sa validité (non expiré)
    const result = await pool.query(
      `SELECT utilisateur_id FROM securite_comptes
       WHERE reset_password_token = $1
       AND reset_password_expires > NOW()`,
      [token]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({ message: 'Token invalide ou expiré' });
    }

    const userId = result.rows[0].utilisateur_id;

    // 2. Hasher le nouveau mot de passe
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(nouveauMotDePasse, saltRounds);

    // 3. Mettre à jour le mot de passe dans la table utilisateurs
    await pool.query(
      'UPDATE utilisateurs SET mot_de_passe_hash = $1 WHERE id = $2',
      [hashedPassword, userId]
    );

    // 4. Supprimer le token (pour qu'il ne soit pas réutilisé)
    await pool.query(
      'DELETE FROM securite_comptes WHERE utilisateur_id = $1',
      [userId]
    );

    res.status(200).json({ message: 'Mot de passe réinitialisé avec succès' });
  } catch (error) {
    console.error('❌ Erreur réinitialisation mot de passe:', error);
    const message = process.env.NODE_ENV === 'development'
      ? error.message
      : 'Erreur serveur';
    res.status(500).json({ message });
  }
});

module.exports = router;