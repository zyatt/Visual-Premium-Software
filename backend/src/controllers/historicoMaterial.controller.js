const historicoSvc = require('../services/historicoMaterial.service');
const { asyncHandler } = require('../middlewares/errorHandler');

const historicoMaterialController = {
  listarGeral: asyncHandler(async (req, res) => {
    const { page, limit, acao } = req.query;
    const historico = await historicoSvc.listarGeral({ page, limit, acao });
    res.json(historico);
  }),

  listarPorMaterial: asyncHandler(async (req, res) => {
    const historico = await historicoSvc.listarPorMaterial(req.params.id);
    res.json(historico);
  }),
};

module.exports = historicoMaterialController;