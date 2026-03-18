// mining-grid-backend/controllers/minerController.js

const minerService = require('../services/minerService');

// GET /api/miners
exports.getMiners = async (req, res, next) => {
  try {
    const miners = await minerService.getAllMiners();
    res.json(miners);
  } catch (err) {
    next(err);
  }
};

// GET /api/miners/:id
exports.getMiner = async (req, res, next) => {
  try {
    const miner = await minerService.getMinerById(req.params.id);
    res.json(miner);
  } catch (err) {
    next(err);
  }
};

// PATCH /api/miners/:id
exports.updateMiner = async (req, res, next) => {
  try {
    const miner = await minerService.updateMiner(req.params.id, req.body);
    res.json(miner);
  } catch (err) {
    next(err);
  }
};

// POST /api/miners/:id/restart
exports.restartMiner = async (req, res, next) => {
  try {
    const miner = await minerService.restartMiner(req.params.id);
    res.json({ message: 'Redémarrage en cours', miner });
  } catch (err) {
    next(err);
  }
};

// POST /api/miners/:id/stop
exports.stopMiner = async (req, res, next) => {
  try {
    const miner = await minerService.stopMiner(req.params.id);
    res.json({ message: 'Mineur arrêté', miner });
  } catch (err) {
    next(err);
  }
};

// POST /api/miners/:id/start
exports.startMiner = async (req, res, next) => {
  try {
    const miner = await minerService.startMiner(req.params.id);
    res.json({ message: 'Mineur démarré', miner });
  } catch (err) {
    next(err);
  }
};

// GET /api/miners/stats/global (ou un endpoint dédié)
exports.getStats = async (req, res, next) => {
  try {
    const stats = await minerService.getGlobalStats();
    res.json(stats);
  } catch (err) {
    next(err);
  }
};