const express = require('express');
const router = express.Router();
const ordemCompraController = require('../controllers/ordemCompra.controller');

router.get('/', ordemCompraController.listarTodos);
router.get('/:id', ordemCompraController.buscarPorId);
router.post('/', ordemCompraController.criar);
router.put('/:id', ordemCompraController.atualizar);
router.patch('/:id/cancelar', ordemCompraController.cancelar);
router.patch('/:id/finalizar', ordemCompraController.finalizar);
router.post('/:id/itens', ordemCompraController.adicionarItem);
router.delete('/:id/itens/:itemId', ordemCompraController.removerItem);

module.exports = router;