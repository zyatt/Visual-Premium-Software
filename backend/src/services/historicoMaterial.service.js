const prisma = require('../utils/prisma');

const historicoMaterialService = {
  /**
   * Registra uma ação no histórico do material.
   * @param {number} materialId
   * @param {'CADASTRO'|'EDICAO'|'INATIVADO'|'REATIVADO'|'SAIDA'|'ENTRADA'} acao
   * @param {object|null} camposAlterados  ex: { nome: { de: 'A', para: 'B' } }
   * @param {string|null} observacoes
   * @param {object} tx  transação Prisma (opcional)
   */
  async registrar(materialId, acao, camposAlterados = null, observacoes = null, tx = prisma) {
    return tx.historicoMaterial.create({
      data: {
        materialId: Number(materialId),
        acao,
        camposAlterados: camposAlterados ? JSON.stringify(camposAlterados) : null,
        observacoes,
      },
    });
  },

  async listarPorMaterial(materialId) {
    return prisma.historicoMaterial.findMany({
      where: { materialId: Number(materialId) },
      include: { material: { select: { id: true, nome: true } } },
      orderBy: { createdAt: 'desc' },
    });
  },

  async listarGeral({ page = 1, limit = 100, acao } = {}) {
    const where = acao ? { acao } : {};
    return prisma.historicoMaterial.findMany({
      where,
      include: { material: { select: { id: true, nome: true, unidade: true } } },
      orderBy: { createdAt: 'desc' },
      take: Number(limit),
      skip: (Number(page) - 1) * Number(limit),
    });
  },

  /**
   * Compara dois objetos e retorna apenas os campos que mudaram.
   * { campo: { de: valorAntigo, para: valorNovo } }
   */
  diffCampos(antes, depois, campos) {
    const diff = {};
    for (const campo of campos) {
      const vAntes = antes[campo];
      const vDepois = depois[campo];
      if (vAntes !== vDepois) {
        diff[campo] = { de: vAntes, para: vDepois };
      }
    }
    return Object.keys(diff).length > 0 ? diff : null;
  },
};

module.exports = historicoMaterialService;