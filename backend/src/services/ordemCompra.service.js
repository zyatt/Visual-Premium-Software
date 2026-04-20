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
        itens: { include: { material: true, fornecedor: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  },

  async buscarPorId(id) {
    const oc = await prisma.ordemCompra.findUnique({
      where: { id: Number(id) },
      include: {
        fornecedor: true,
        itens: { include: { material: true, fornecedor: true } },
        historico: {
          include: { material: { select: { nome: true } } },
          orderBy: { createdAt: 'desc' },
        },
      },
    });
    if (!oc) throw { status: 404, message: 'Ordem de compra não encontrada' };
    return oc;
  },

  async proximoNumero() {
    const ultima = await prisma.ordemCompra.findFirst({
      orderBy: { numeroOC: 'desc' },
      select: { numeroOC: true },
    });
    return { proximoNumero: ultima ? ultima.numeroOC + 1 : 1 };
  },

  async criar(dados) {
    const { data, formaPagamento, fornecedorId, observacoes, itens = [] } = dados;

    const oc = await prisma.ordemCompra.create({
      data: {
        data: data ? new Date(data) : new Date(),
        ...(formaPagamento ? { formaPagamento } : {}),
        ...(fornecedorId ? { fornecedorId: Number(fornecedorId) } : {}),
        ...(observacoes ? { observacoes } : {}),
        status: 'EM_ANDAMENTO',
        itens: {
          create: itens.map((item) => ({
            materialId: Number(item.materialId),
            ...(item.fornecedorId ? { fornecedorId: Number(item.fornecedorId) } : {}),
            quantidade: item.quantidade,
            precoUnitario: item.precoUnitario,
            precoTotal: item.precoUnitario * item.quantidade,
            ...(item.prazoEntrega ? { prazoEntrega: item.prazoEntrega } : {}),
            ...(item.observacoes ? { observacoes: item.observacoes } : {}),
          })),
        },
      },
      include: {
        fornecedor: true,
        itens: { include: { material: true, fornecedor: true } },
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

    if (itens) {
      await prisma.ordemCompraItem.deleteMany({ where: { ordemCompraId: Number(id) } });
    }

    return prisma.ordemCompra.update({
      where: { id: Number(id) },
      data: {
        ...(dadosOC.numeroOC !== undefined ? { numeroOC: dadosOC.numeroOC } : {}),
        ...(dadosOC.data ? { data: new Date(dadosOC.data) } : {}),
        ...(dadosOC.formaPagamento !== undefined ? { formaPagamento: dadosOC.formaPagamento || null } : {}),
        ...(dadosOC.fornecedorId !== undefined
          ? { fornecedorId: dadosOC.fornecedorId ? Number(dadosOC.fornecedorId) : null }
          : {}),
        ...(dadosOC.observacoes !== undefined ? { observacoes: dadosOC.observacoes || null } : {}),
        ...(itens && {
          itens: {
            create: itens.map((item) => ({
              materialId: Number(item.materialId),
              ...(item.fornecedorId ? { fornecedorId: Number(item.fornecedorId) } : {}),
              quantidade: item.quantidade,
              precoUnitario: item.precoUnitario,
              precoTotal: item.precoUnitario * item.quantidade,
              ...(item.prazoEntrega ? { prazoEntrega: item.prazoEntrega } : {}),
              ...(item.observacoes ? { observacoes: item.observacoes } : {}),
            })),
          },
        }),
      },
      include: {
        fornecedor: true,
        itens: { include: { material: true, fornecedor: true } },
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
      include: { itens: { include: { material: true, fornecedor: true } } },
    });
    if (!oc) throw { status: 404, message: 'Ordem de compra não encontrada' };
    if (oc.status !== 'EM_ANDAMENTO') {
      throw { status: 400, message: `OC com status "${oc.status}" não pode ser finalizada` };
    }

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
        ...(item.fornecedorId ? { fornecedorId: Number(item.fornecedorId) } : {}),
        quantidade: item.quantidade,
        precoUnitario: item.precoUnitario,
        precoTotal: item.precoUnitario * item.quantidade,
        ...(item.prazoEntrega ? { prazoEntrega: item.prazoEntrega } : {}),
        ...(item.observacoes ? { observacoes: item.observacoes } : {}),
      },
      include: { material: true },
    });
  },

  async removerItem(ordemId, itemId) {
    return prisma.ordemCompraItem.delete({
      where: { id: Number(itemId) },
    });
  },

  async listarHistorico({ dataInicio, dataFim } = {}) {
    const where = {
      tipoMovimento: 'ENTRADA',
      ordemCompraId: { not: null },
    };

    if (dataInicio || dataFim) {
      where.createdAt = {};
      if (dataInicio) where.createdAt.gte = new Date(dataInicio);
      if (dataFim)    where.createdAt.lte = new Date(dataFim);
    }

    const registros = await prisma.historicoEstoque.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: {
        material: { select: { nome: true } },
        ordemCompra: {
          select: {
            numeroOC: true,
            fornecedor: { select: { nome: true } },
          },
        },
      },
    });

    return registros.map((r) => ({
      id:               r.id,
      ordemCompraId:    r.ordemCompraId,
      numeroOC:         r.ordemCompra?.numeroOC ?? 0,
      materialId:       r.materialId,
      materialNome:     r.material?.nome ?? `Material ${r.materialId}`,
      fornecedorNome:   r.ordemCompra?.fornecedor?.nome ?? null,
      quantidade:       r.quantidade,
      quantidadeAntes:  r.quantidadeAntes,
      quantidadeDepois: r.quantidadeDepois,
      custo:            r.custo,
      observacoes:      r.observacoes ?? null,
      data:             r.createdAt.toISOString(),
    }));
  },
};

module.exports = ordemCompraService;