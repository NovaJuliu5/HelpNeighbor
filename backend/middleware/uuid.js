function validateUuidParam(paramName) {
  return (req, res, next) => {
    const value = req.params[paramName];
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(value)) {
      return res.status(400).json({ message: `ID invalide : '${value}' (attendu un UUID)` });
    }
    next();
  };
}

module.exports = { validateUuidParam };