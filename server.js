// mining-grid-backend/server.js

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const connectDB = require('./config/database');
const minerRoutes = require('./routes/minerRoutes');
const errorHandler = require('./middleware/errorHandler');

const app = express();
const PORT = process.env.PORT || 3000;

// Connexion à MongoDB
connectDB();

// Middleware globaux
app.use(cors());
app.use(bodyParser.json());

// Routes
app.use('/api/miners', minerRoutes);
app.get('/api/health', (req, res) => res.json({ status: 'OK' }));

// Gestion des erreurs (doit être après les routes)
app.use(errorHandler);

// Démarrage du serveur
app.listen(PORT, () => {
  console.log(`Serveur démarré sur le port ${PORT}`);
  console.log(`Environnement : ${process.env.NODE_ENV}`);
});