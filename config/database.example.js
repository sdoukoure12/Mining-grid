// config/database.example.js
// Copy this file to database.js and configure via environment variables.
// Never hardcode credentials in source code.

const mongoose = require('mongoose');

const connectDB = async () => {
  const uri = process.env.MONGO_URI;

  if (!uri) {
    console.error('MONGO_URI environment variable is not set. Copy .env.example to .env and fill in your credentials.');
    process.exit(1);
  }

  try {
    await mongoose.connect(uri, {
      // Recommended options for production
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
    });
    console.log('MongoDB connected');
  } catch (err) {
    console.error('MongoDB connection error:', err.message);
    process.exit(1);
  }
};

module.exports = connectDB;
