// mining-grid-backend/services/minerService.js

const Miner = require('../models/Miner');

/**
 * Récupère tous les mineurs
 */
exports.getAllMiners = async () => {
  return await Miner.find().sort({ createdAt: -1 });
};

/**
 * Récupère un mineur par son ID
 */
exports.getMinerById = async (id) => {
  const miner = await Miner.findById(id);
  if (!miner) throw new Error('Mineur non trouvé');
  return miner;
};

/**
 * Met à jour partiellement un mineur (champs autorisés)
 */
exports.updateMiner = async (id, updates) => {
  const allowed = ['name', 'powerLimit'];
  const filteredUpdates = {};
  for (const key of allowed) {
    if (updates[key] !== undefined) filteredUpdates[key] = updates[key];
  }

  const miner = await Miner.findByIdAndUpdate(id, filteredUpdates, {
    new: true,
    runValidators: true,
  });
  if (!miner) throw new Error('Mineur non trouvé');
  return miner;
};

/**
 * Redémarre un mineur
 */
exports.restartMiner = async (id) => {
  const miner = await Miner.findById(id);
  if (!miner) throw new Error('Mineur non trouvé');

  miner.status = 'restarting';
  await miner.save();

  // Simuler un redémarrage asynchrone (en production, appeler un service réel)
  setTimeout(async () => {
    miner.status = 'active';
    miner.uptime = 0;
    await miner.save();
  }, 10000);

  return miner;
};

/**
 * Arrête un mineur
 */
exports.stopMiner = async (id) => {
  const miner = await Miner.findById(id);
  if (!miner) throw new Error('Mineur non trouvé');

  miner.status = 'inactive';
  miner.hashrate = 0;
  miner.power = 0;
  miner.profitability = 0;
  await miner.save();

  return miner;
};

/**
 * Démarre un mineur
 */
exports.startMiner = async (id) => {
  const miner = await Miner.findById(id);
  if (!miner) throw new Error('Mineur non trouvé');

  miner.status = 'active';
  miner.hashrate = 95.0; // valeur par défaut
  miner.temperature = 40;
  miner.power = 3300;
  miner.profitability = 0.00004;
  miner.uptime = 0;
  await miner.save();

  return miner;
};

/**
 * Récupère les statistiques globales
 */
exports.getGlobalStats = async () => {
  const miners = await Miner.find();
  const activeMiners = miners.filter(m => m.status === 'active');
  const totalHashrate = activeMiners.reduce((sum, m) => sum + m.hashrate, 0);
  const avgTemp = activeMiners.length
    ? activeMiners.reduce((sum, m) => sum + m.temperature, 0) / activeMiners.length
    : 0;
  const totalPower = activeMiners.reduce((sum, m) => sum + m.power, 0);
  const totalProfitability = miners.reduce((sum, m) => sum + m.profitability, 0);

  return {
    totalMiners: miners.length,
    activeMiners: activeMiners.length,
    totalHashrate,
    averageTemperature: avgTemp,
    totalPower,
    totalProfitability,
  };
};