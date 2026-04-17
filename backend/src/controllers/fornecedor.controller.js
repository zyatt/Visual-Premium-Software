const fornecedorService = require('../services/fornecedor.service');
const { asyncHandler } = require('../middlewares/errorHandler');

const fornecedorController = {
  listarTodos: asyncHandler(async (req, res) => {
    const fornecedores = await fornecedorService.listarTodos();
    res.json(fornecedores);
  }),

  buscarPorId: asyncHandler(async (req, res) => {
    const fornecedor = await fornecedorService.buscarPorId(req.params.id);
    res.json(fornecedor);
  }),

  criar: asyncHandler(async (req, res) => {
    const fornecedor = await fornecedorService.criar(req.body);
    res.status(201).json(fornecedor);
  }),

  atualizar: asyncHandler(async (req, res) => {
    const fornecedor = await fornecedorService.atualizar(req.params.id, req.body);
    res.json(fornecedor);
  }),

  deletar: asyncHandler(async (req, res) => {
    await fornecedorService.deletar(req.params.id);
    res.status(204).send();
  }),

  adicionarMaterial: asyncHandler(async (req, res) => {
    const { materialId, custo, prazoEntrega } = req.body;
    const rel = await fornecedorService.adicionarMaterial(
      req.params.id, materialId, custo, prazoEntrega
    );
    res.status(201).json(rel);
  }),

  removerMaterial: asyncHandler(async (req, res) => {
    await fornecedorService.removerMaterial(req.params.id, req.params.materialId);
    res.status(204).send();
  }),
};

module.exports = fornecedorController;