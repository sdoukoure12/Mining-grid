// mining-grid-backend/routes/minerRoutes.js

const express = require('express');
const router = express.Router();
const minerController = require('../controllers/minerController');
const validateId = require('../middleware/validateId');

// Routes sans paramètre ID
router.get('/', minerController.getMiners);
router.get('/stats', minerController.getStats);

// Routes avec paramètre ID (validation incluse)
router.get('/:id', validateId, minerController.getMiner);
router.patch('/:id', validateId, minerController.updateMiner);
router.post('/:id/restart', validateId, minerController.restartMiner);
router.post('/:id/stop', validateId, minerController.stopMiner);
router.post('/:id/start', validateId, minerController.startMiner);

module.exports = router;