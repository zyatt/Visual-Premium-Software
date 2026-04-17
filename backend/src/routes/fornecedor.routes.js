const express = require('express');
const router = express.Router();
const fornecedorController = require('../controllers/fornecedor.controller');

router.get('/', fornecedorController.listarTodos);
router.get('/:id', fornecedorController.buscarPorId);
router.post('/', fornecedorController.criar);
router.put('/:id', fornecedorController.atualizar);
router.delete('/:id', fornecedorController.deletar);
router.post('/:id/materiais', fornecedorController.adicionarMaterial);
router.delete('/:id/materiais/:materialId', fornecedorController.removerMaterial);

module.exports = router;