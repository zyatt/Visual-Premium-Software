const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/historicoMaterial.controller');

router.get('/', ctrl.listarGeral);
router.get('/material/:id', ctrl.listarPorMaterial);

module.exports = router;