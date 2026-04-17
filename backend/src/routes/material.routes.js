const express = require('express');
const router = express.Router();
const materialController = require('../controllers/material.controller');

router.get('/', materialController.listarTodos);
router.get('/historico', materialController.historicoGeral);
router.get('/:id', materialController.buscarPorId);
router.post('/', materialController.criar);
router.put('/:id', materialController.atualizar);
router.delete('/:id', materialController.deletar);
router.post('/:id/saida', materialController.registrarSaida);
router.get('/:id/historico', materialController.buscarHistorico);

module.exports = router;