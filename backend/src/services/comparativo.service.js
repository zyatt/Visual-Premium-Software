const prisma = require('../utils/prisma');

const comparativoService = {
  async compararMaterial(materialId) {
    const material = await prisma.material.findUnique({
      where: { id: Number(materialId) },
      include: {
        fornecedorMateriais: {
          include: { fornecedor: true },
          orderBy: { custo: 'asc' },
        },
      },
    });

    if (!material) throw { status: 404, message: 'Material não encontrado' };
    if (material.status === 'INATIVO') throw { status: 404, message: 'Material não encontrado' };
    if (!material.fornecedorMateriais.length) {
      return { material, fornecedores: [], melhorFornecedor: null };
    }

    const fornecedores = material.fornecedorMateriais.map((fm) => ({
      fornecedorId: fm.fornecedorId,
      fornecedorNome: fm.fornecedor.nome,
      custo: fm.custo,
      prazoEntrega: fm.prazoEntrega,
      melhorPreco: false,
    }));

    fornecedores[0].melhorPreco = true; // já ordenado por custo asc

    return { material, fornecedores, melhorFornecedor: fornecedores[0] };
  },

  async compararPorOrdemCompra(ordemCompraId) {
    const oc = await prisma.ordemCompra.findUnique({
      where: { id: Number(ordemCompraId) },
      include: {
        itens: {
          include: {
            material: {
              include: {
                fornecedorMateriais: {
                  include: { fornecedor: true },
                  orderBy: { custo: 'asc' },
                },
              },
            },
          },
        },
        fornecedor: true,
      },
    });

    if (!oc) throw { status: 404, message: 'Ordem de compra não encontrada' };

    const comparativos = oc.itens
      .filter((item) => item.material.status !== 'INATIVO')
      .map((item) => {
      const fornecedores = item.material.fornecedorMateriais.map((fm, idx) => ({
        fornecedorId: fm.fornecedorId,
        fornecedorNome: fm.fornecedor.nome,
        custo: fm.custo,
        prazoEntrega: fm.prazoEntrega,
        melhorPreco: idx === 0,
      }));

      return {
        materialId: item.materialId,
        materialNome: item.material.nome,
        precoNaOC: item.precoUnitario,
        fornecedores,
        melhorFornecedor: fornecedores[0] || null,
      };
    });

    return { ordemCompra: oc, comparativos };
  },

  async compararMultiplosMateriais(materialIds) {
    const resultados = await Promise.all(
      materialIds.map((id) => this.compararMaterial(id))
    );
    return resultados;
  },
};

module.exports = comparativoService;