// mining-grid/server.js
// Serveur backend pour la grille de surveillance des mineurs
// Fournit des API REST pour gérer les mineurs et les statistiques

const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
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

// Middleware
app.use(cors());
app.use(bodyParser.json());

// ========== Données simulées (en mémoire) ==========
let miners = [
  {
    id: 'miner-001',
    name: 'Mineur A1',
    status: 'active',
    hashrate: 98.5,
    temperature: 65,
    uptime: 345600, // 4 jours en secondes
    power: 3250,
    profitability: 0.000045,
    powerLimit: 3500,
  },
  {
    id: 'miner-002',
    name: 'Mineur B2',
    status: 'active',
    hashrate: 102.3,
    temperature: 72,
    uptime: 864000, // 10 jours
    power: 3420,
    profitability: 0.000048,
    powerLimit: 3500,
  },
  {
    id: 'miner-003',
    name: 'Mineur C3',
    status: 'inactive',
    hashrate: 0,
    temperature: 30,
    uptime: 0,
    power: 0,
    profitability: 0,
    powerLimit: 3500,
  },
  {
    id: 'miner-004',
    name: 'Mineur D4',
    status: 'warning',
    hashrate: 45.2,
    temperature: 82,
    uptime: 172800, // 2 jours
    power: 3100,
    profitability: 0.000022,
    powerLimit: 3500,
  },
];

// ========== Routes API ==========

// GET /api/miners – liste de tous les mineurs
app.get('/api/miners', (req, res) => {
  res.json(miners);
});

// GET /api/miners/:id – détail d’un mineur
app.get('/api/miners/:id', (req, res) => {
  const miner = miners.find(m => m.id === req.params.id);
  if (!miner) {
    return res.status(404).json({ error: 'Mineur non trouvé' });
  }
  res.json(miner);
});

// PATCH /api/miners/:id – mise à jour partielle
app.patch('/api/miners/:id', (req, res) => {
  const index = miners.findIndex(m => m.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ error: 'Mineur non trouvé' });
  }

  // Champs autorisés à être modifiés
  const allowedUpdates = ['name', 'powerLimit'];
  const updates = req.body;

  for (const key of Object.keys(updates)) {
    if (allowedUpdates.includes(key)) {
      miners[index][key] = updates[key];
    }
  }

  res.json(miners[index]);
});

// POST /api/miners/:id/restart – redémarrer un mineur
app.post('/api/miners/:id/restart', (req, res) => {
  const miner = miners.find(m => m.id === req.params.id);
  if (!miner) {
    return res.status(404).json({ error: 'Mineur non trouvé' });
  }

  // Simuler un redémarrage (le statut devient actif après quelques secondes)
  miner.status = 'restarting';
  setTimeout(() => {
    miner.status = 'active';
    miner.uptime = 0;
    // On pourrait aussi remettre le hashrate, etc.
  }, 10000);

  res.json({ message: 'Redémarrage en cours', miner });
});

// POST /api/miners/:id/stop – arrêter un mineur
app.post('/api/miners/:id/stop', (req, res) => {
  const miner = miners.find(m => m.id === req.params.id);
  if (!miner) {
    return res.status(404).json({ error: 'Mineur non trouvé' });
  }

  miner.status = 'inactive';
  miner.hashrate = 0;
  miner.power = 0;
  miner.profitability = 0;
  // On pourrait garder l'uptime figé ou le réinitialiser

  res.json({ message: 'Mineur arrêté', miner });
});

// POST /api/miners/:id/start – démarrer un mineur
app.post('/api/miners/:id/start', (req, res) => {
  const miner = miners.find(m => m.id === req.params.id);
  if (!miner) {
    return res.status(404).json({ error: 'Mineur non trouvé' });
  }

  miner.status = 'active';
  miner.hashrate = 95.0; // valeur par défaut
  miner.temperature = 40;
  miner.power = 3300;
  miner.profitability = 0.000040;
  miner.uptime = 0;

  res.json({ message: 'Mineur démarré', miner });
});

// GET /api/stats – statistiques globales
app.get('/api/stats', (req, res) => {
  const activeMiners = miners.filter(m => m.status === 'active');
  const totalHashrate = activeMiners.reduce((sum, m) => sum + m.hashrate, 0);
  const avgTemp = activeMiners.length
    ? activeMiners.reduce((sum, m) => sum + m.temperature, 0) / activeMiners.length
    : 0;
  const totalPower = activeMiners.reduce((sum, m) => sum + m.power, 0);
  const totalProfitability = miners.reduce((sum, m) => sum + m.profitability, 0);

  res.json({
    totalMiners: miners.length,
    activeMiners: activeMiners.length,
    totalHashrate,
    averageTemperature: avgTemp,
    totalPower,
    totalProfitability,
    // on peut ajouter d'autres métriques
  });
});

// ========== Démarrage du serveur ==========
app.listen(PORT, () => {
  console.log(`Serveur Mining Grid démarré sur le port ${PORT}`);
  console.log(`API disponible sur http://localhost:${PORT}/api`);
});

// Gestion des erreurs non capturées (facultatif)
process.on('uncaughtException', (err) => {
  console.error('Exception non capturée :', err);
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