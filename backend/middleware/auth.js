console.log(' Chargement du middleware auth.js');

const jwt = require('jsonwebtoken');
const JWT_SECRET = 'votre_secret_jwt';

function authenticateToken(req, res, next) {
  console.log(` Authentification - requête ${req.method} ${req.url}`);
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) {
    console.log(' Authentification échouée : aucun token');
    return res.sendStatus(401);
  }
  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      console.log(' Authentification échouée : token invalide');
      return res.sendStatus(403);
    }
    console.log(` Authentification réussie pour l'utilisateur ${user.id}`);
    req.user = user;
    next();
  });
}

console.log(' Middleware auth.js exporté avec succès');
module.exports = { authenticateToken, JWT_SECRET };