console.log(' Chargement du middleware uuid.js');

function validateUuidParam(paramName) {
  console.log(` validateUuidParam appelé avec paramName: ${paramName}`);
  return (req, res, next) => {
    const value = req.params[paramName];
    console.log(` Validation UUID pour paramètre '${paramName}' = '${value}'`);
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(value)) {
      console.log(` UUID invalide : '${value}'`);
      return res.status(400).json({ message: `ID invalide : '${value}' (attendu un UUID)` });
    }
    console.log(` UUID valide : '${value}'`);
    next();
  };
}

console.log(' Middleware uuid.js exporté avec succès');
module.exports = { validateUuidParam };