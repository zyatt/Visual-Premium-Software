const comparativoService = require('../services/comparativo.service');
const { asyncHandler } = require('../middlewares/errorHandler');

const comparativoController = {
  compararMaterial: asyncHandler(async (req, res) => {
    const resultado = await comparativoService.compararMaterial(req.params.materialId);
    res.json(resultado);
  }),

  compararPorOrdemCompra: asyncHandler(async (req, res) => {
    const resultado = await comparativoService.compararPorOrdemCompra(req.params.ordemCompraId);
    res.json(resultado);
  }),

  compararMultiplosMateriais: asyncHandler(async (req, res) => {
    const { materialIds } = req.body;
    const resultado = await comparativoService.compararMultiplosMateriais(materialIds);
    res.json(resultado);
  }),
};

module.exports = comparativoController;