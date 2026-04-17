const prisma = require('../utils/prisma');

const calcularStatus = (quantidadeAtual, estoqueMinimo) => {
  if (quantidadeAtual <= 0) return 'CRITICO';
  if (quantidadeAtual <= estoqueMinimo) return 'BAIXO';
  return 'OK';
};

const ordemCompraService = {
  async listarTodos() {
    return prisma.ordemCompra.findMany({
      include: {
        fornecedor: true,
        itens: { include: { material: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  },

  async buscarPorId(id) {
    const oc = await prisma.ordemCompra.findUnique({
      where: { id: Number(id) },
      include: {
        fornecedor: true,
        itens: { include: { material: true } },
        historico: {
          include: { material: { select: { nome: true } } },
          orderBy: { createdAt: 'desc' },
        },
      },
    });
    if (!oc) throw { status: 404, message: 'Ordem de compra não encontrada' };
    return oc;
  },

  async criar(dados) {
    const { numeroOC, data, formaPagamento, fornecedorId, observacoes, itens = [] } = dados;

    // Verificar se número OC já existe
    const ocExistente = await prisma.ordemCompra.findUnique({ where: { numeroOC } });
    if (ocExistente) throw { status: 409, message: 'Número de OC já cadastrado' };

    const oc = await prisma.ordemCompra.create({
      data: {
        numeroOC,
        data: new Date(data),
        formaPagamento,
        fornecedorId: Number(fornecedorId),
        observacoes,
        status: 'EM_ANDAMENTO',
        itens: {
          create: itens.map((item) => ({
            materialId: Number(item.materialId),
            quantidade: item.quantidade,
            precoUnitario: item.precoUnitario,
            precoTotal: item.precoUnitario * item.quantidade,
            prazoEntrega: item.prazoEntrega,
            observacoes: item.observacoes,
          })),
        },
      },
      include: {
        fornecedor: true,
        itens: { include: { material: true } },
      },
    });

    return oc;
  },

  async atualizar(id, dados) {
    const oc = await prisma.ordemCompra.findUnique({ where: { id: Number(id) } });
    if (!oc) throw { status: 404, message: 'Ordem de compra não encontrada' };
    if (oc.status === 'FINALIZADO') throw { status: 400, message: 'OC finalizada não pode ser editada' };
    if (oc.status === 'CANCELADO') throw { status: 400, message: 'OC cancelada não pode ser editada' };

    const { itens, ...dadosOC } = dados;

    // Se itens fornecidos, substituir todos
    if (itens) {
      await prisma.ordemCompraItem.deleteMany({ where: { ordemCompraId: Number(id) } });
    }

    return prisma.ordemCompra.update({
      where: { id: Number(id) },
      data: {
        ...dadosOC,
        data: dadosOC.data ? new Date(dadosOC.data) : undefined,
        fornecedorId: dadosOC.fornecedorId ? Number(dadosOC.fornecedorId) : undefined,
        ...(itens && {
          itens: {
            create: itens.map((item) => ({
              materialId: Number(item.materialId),
              quantidade: item.quantidade,
              precoUnitario: item.precoUnitario,
              precoTotal: item.precoUnitario * item.quantidade,
              prazoEntrega: item.prazoEntrega,
              observacoes: item.observacoes,
            })),
          },
        }),
      },
      include: {
        fornecedor: true,
        itens: { include: { material: true } },
      },
    });
  },

  async cancelar(id) {
    const oc = await prisma.ordemCompra.findUnique({ where: { id: Number(id) } });
    if (!oc) throw { status: 404, message: 'Ordem de compra não encontrada' };
    if (oc.status === 'FINALIZADO') throw { status: 400, message: 'OC finalizada não pode ser cancelada' };

    return prisma.ordemCompra.update({
      where: { id: Number(id) },
      data: { status: 'CANCELADO' },
    });
  },

  async finalizar(id) {
    const oc = await prisma.ordemCompra.findUnique({
      where: { id: Number(id) },
      include: { itens: { include: { material: true } } },
    });
    if (!oc) throw { status: 404, message: 'Ordem de compra não encontrada' };
    if (oc.status !== 'EM_ANDAMENTO') {
      throw { status: 400, message: `OC com status "${oc.status}" não pode ser finalizada` };
    }

    // Transação: atualizar estoque e criar histórico
    await prisma.$transaction(async (tx) => {
      for (const item of oc.itens) {
        const material = await tx.material.findUnique({ where: { id: item.materialId } });
        const novaQuantidade = material.quantidadeAtual + item.quantidade;
        const status = calcularStatus(novaQuantidade, material.estoqueMinimo);

        await tx.material.update({
          where: { id: item.materialId },
          data: {
            quantidadeAtual: novaQuantidade,
            ultimoValorPago: item.precoUnitario,
            status,
          },
        });

        await tx.historicoEstoque.create({
          data: {
            materialId: item.materialId,
            ordemCompraId: oc.id,
            tipoMovimento: 'ENTRADA',
            quantidade: item.quantidade,
            quantidadeAntes: material.quantidadeAtual,
            quantidadeDepois: novaQuantidade,
            custo: item.precoUnitario,
            observacoes: `Entrada via OC ${oc.numeroOC}`,
          },
        });
      }

      await tx.ordemCompra.update({
        where: { id: Number(id) },
        data: { status: 'FINALIZADO' },
      });
    });

    return this.buscarPorId(id);
  },

  async adicionarItem(ordemId, item) {
    const oc = await prisma.ordemCompra.findUnique({ where: { id: Number(ordemId) } });
    if (!oc) throw { status: 404, message: 'Ordem de compra não encontrada' };
    if (oc.status !== 'EM_ANDAMENTO') throw { status: 400, message: 'Só é possível adicionar itens em OC em andamento' };

    return prisma.ordemCompraItem.create({
      data: {
        ordemCompraId: Number(ordemId),
        materialId: Number(item.materialId),
        quantidade: item.quantidade,
        precoUnitario: item.precoUnitario,
        precoTotal: item.precoUnitario * item.quantidade,
        prazoEntrega: item.prazoEntrega,
        observacoes: item.observacoes,
      },
      include: { material: true },
    });
  },

  async removerItem(ordemId, itemId) {
    return prisma.ordemCompraItem.delete({
      where: { id: Number(itemId) },
    });
  },
};

module.exports = ordemCompraService;