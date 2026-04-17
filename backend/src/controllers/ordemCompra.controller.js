const ordemCompraService = require('../services/ordemCompra.service');
const { asyncHandler } = require('../middlewares/errorHandler');

const ordemCompraController = {
  listarTodos: asyncHandler(async (req, res) => {
    const ordens = await ordemCompraService.listarTodos();
    res.json(ordens);
  }),

  buscarPorId: asyncHandler(async (req, res) => {
    const ordem = await ordemCompraService.buscarPorId(req.params.id);
    res.json(ordem);
  }),

  criar: asyncHandler(async (req, res) => {
    const ordem = await ordemCompraService.criar(req.body);
    res.status(201).json(ordem);
  }),

  atualizar: asyncHandler(async (req, res) => {
    const ordem = await ordemCompraService.atualizar(req.params.id, req.body);
    res.json(ordem);
  }),

  cancelar: asyncHandler(async (req, res) => {
    const ordem = await ordemCompraService.cancelar(req.params.id);
    res.json(ordem);
  }),

  finalizar: asyncHandler(async (req, res) => {
    const ordem = await ordemCompraService.finalizar(req.params.id);
    res.json(ordem);
  }),

  adicionarItem: asyncHandler(async (req, res) => {
    const item = await ordemCompraService.adicionarItem(req.params.id, req.body);
    res.status(201).json(item);
  }),

  removerItem: asyncHandler(async (req, res) => {
    await ordemCompraService.removerItem(req.params.id, req.params.itemId);
    res.status(204).send();
  }),
};

module.exports = ordemCompraController;