// mining-grid-backend/models/Miner.js

const mongoose = require('mongoose');

const minerSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Le nom est requis'],
      trim: true,
      maxlength: [50, 'Le nom ne peut pas dépasser 50 caractères'],
    },
    status: {
      type: String,
      enum: ['active', 'inactive', 'warning', 'restarting'],
      default: 'inactive',
    },
    hashrate: {
      type: Number,
      default: 0,
      min: 0,
    },
    temperature: {
      type: Number,
      default: 0,
      min: 0,
      max: 120,
    },
    uptime: {
      type: Number, // en secondes
      default: 0,
      min: 0,
    },
    power: {
      type: Number, // consommation en watts
      default: 0,
      min: 0,
    },
    profitability: {
      type: Number, // BTC par jour
      default: 0,
      min: 0,
    },
    powerLimit: {
      type: Number,
      default: 3500,
      min: 0,
    },
  },
  {
    timestamps: true, // ajoute createdAt et updatedAt
  }
);

module.exports = mongoose.model('Miner', minerSchema);