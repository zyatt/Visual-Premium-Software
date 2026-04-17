const materialService = require('../services/material.service');
const { asyncHandler } = require('../middlewares/errorHandler');

const estoqueController = {
  resumo: asyncHandler(async (req, res) => {
    const materiais = await materialService.listarTodos();
    const total = materiais.length;
    const ok = materiais.filter((m) => m.status === 'OK').length;
    const baixo = materiais.filter((m) => m.status === 'BAIXO').length;
    const critico = materiais.filter((m) => m.status === 'CRITICO').length;

    res.json({ total, ok, baixo, critico, materiais });
  }),

  historico: asyncHandler(async (req, res) => {
    const historico = await materialService.historicoGeral();
    res.json(historico);
  }),
};

module.exports = estoqueController;