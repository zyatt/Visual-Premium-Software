const express = require('express');
const router = express.Router();
const comparativoController = require('../controllers/comparativo.controller');

router.get('/material/:materialId', comparativoController.compararMaterial);
router.get('/ordem-compra/:ordemCompraId', comparativoController.compararPorOrdemCompra);
router.post('/materiais', comparativoController.compararMultiplosMateriais);

module.exports = router;