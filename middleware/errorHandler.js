// mining-grid-backend/middleware/errorHandler.js

module.exports = (err, req, res, next) => {
  console.error(err.stack);

  // Erreur Mongoose / validation
  if (err.name === 'ValidationError') {
    return res.status(400).json({ error: err.message });
  }

  // Erreur personnalisée (ex: "Mineur non trouvé")
  if (err.message === 'Mineur non trouvé') {
    return res.status(404).json({ error: err.message });
  }

  // Erreur par défaut
  res.status(500).json({ error: 'Erreur interne du serveur' });
};