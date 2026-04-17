const express = require('express');
const router = express.Router();
const estoqueController = require('../controllers/estoque.controller');

router.get('/resumo', estoqueController.resumo);
router.get('/historico', estoqueController.historico);

module.exports = router;