const materialService = require('../services/material.service');
const { asyncHandler } = require('../middlewares/errorHandler');

const materialController = {
  listarTodos: asyncHandler(async (req, res) => {
    const materiais = await materialService.listarTodos();
    res.json(materiais);
  }),

  buscarPorId: asyncHandler(async (req, res) => {
    const material = await materialService.buscarPorId(req.params.id);
    res.json(material);
  }),

  criar: asyncHandler(async (req, res) => {
    const material = await materialService.criar(req.body);
    res.status(201).json(material);
  }),

  atualizar: asyncHandler(async (req, res) => {
    const material = await materialService.atualizar(req.params.id, req.body);
    res.json(material);
  }),

  deletar: asyncHandler(async (req, res) => {
    await materialService.deletar(req.params.id);
    res.status(204).send();
  }),

  registrarSaida: asyncHandler(async (req, res) => {
    const { quantidade, observacoes } = req.body;
    const material = await materialService.registrarSaida(req.params.id, quantidade, observacoes);
    res.json(material);
  }),

  buscarHistorico: asyncHandler(async (req, res) => {
    const historico = await materialService.buscarHistorico(req.params.id);
    res.json(historico);
  }),

  historicoGeral: asyncHandler(async (req, res) => {
    const historico = await materialService.historicoGeral();
    res.json(historico);
  }),
};

module.exports = materialController;