const prisma = require('../utils/prisma');
const historicoSvc = require('./historicoMaterial.service');

const calcularStatus = (quantidadeAtual, estoqueMinimo) => {
  if (quantidadeAtual <= 0) return 'CRITICO';
  if (quantidadeAtual <= estoqueMinimo) return 'BAIXO';
  return 'OK';
};

const materialService = {
  async listarTodos() {
    return prisma.material.findMany({
      include: {
        fornecedorMateriais: { include: { fornecedor: true } },
      },
      orderBy: { nome: 'asc' },
    });
  },

  async buscarPorId(id) {
    const material = await prisma.material.findUnique({
      where: { id: Number(id) },
      include: {
        fornecedorMateriais: { include: { fornecedor: true } },
        historicoEstoque: { orderBy: { createdAt: 'desc' }, take: 50 },
      },
    });
    if (!material) throw { status: 404, message: 'Material não encontrado' };
    return material;
  },

  async criar(dados) {
    const {
      nome, unidade = null, quantidadeAtual = 0,
      estoqueInicial = 0, estoqueMinimo = 0, custo = 0, ultimoValorPago = 0,
    } = dados;

    // Verifica nome duplicado
    const existente = await prisma.material.findFirst({
      where: { nome: { equals: nome.trim(), mode: 'insensitive' } },
    });
    if (existente) throw { status: 409, message: `Já existe um material cadastrado com o nome "${nome}"` };

    const status = calcularStatus(quantidadeAtual, estoqueMinimo);

    const material = await prisma.$transaction(async (tx) => {
      const m = await tx.material.create({
        data: { nome, unidade, quantidadeAtual, estoqueInicial, estoqueMinimo, custo, ultimoValorPago, status },
      });

      // Histórico de cadastro
      await historicoSvc.registrar(m.id, 'CADASTRO', null, `Material "${nome}" cadastrado`, tx);

      // Entrada inicial
      if (estoqueInicial > 0) {
        await tx.historicoEstoque.create({
          data: {
            materialId: m.id,
            tipoMovimento: 'ENTRADA',
            quantidade: estoqueInicial,
            quantidadeAntes: 0,
            quantidadeDepois: estoqueInicial,
            custo,
            observacoes: 'Estoque inicial',
          },
        });
        await historicoSvc.registrar(
          m.id, 'ENTRADA',
          { quantidade: { de: 0, para: estoqueInicial } },
          'Estoque inicial registrado',
          tx
        );
      }

      return m;
    });

    return material;
  },

  async atualizar(id, dados) {
    const antes = await prisma.material.findUnique({ where: { id: Number(id) } });
    if (!antes) throw { status: 404, message: 'Material não encontrado' };

    // ── Reativar ──────────────────────────────────────────────────────────────
    if (dados.reativar === true) {
      const novoStatus = calcularStatus(antes.quantidadeAtual, antes.estoqueMinimo);
      const m = await prisma.$transaction(async (tx) => {
        const updated = await tx.material.update({
          where: { id: Number(id) },
          data: { status: novoStatus },
        });
        await historicoSvc.registrar(Number(id), 'REATIVADO', null, `Material reativado (status → ${novoStatus})`, tx);
        return updated;
      });
      return m;
    }

    // ── Inativar ──────────────────────────────────────────────────────────────
    if (dados.status === 'INATIVO') {
      const m = await prisma.$transaction(async (tx) => {
        const updated = await tx.material.update({
          where: { id: Number(id) },
          data: { status: 'INATIVO' },
        });
        await tx.fornecedorMaterial.deleteMany({ where: { materialId: Number(id) } });
        await historicoSvc.registrar(Number(id), 'INATIVADO', null, 'Material inativado', tx);
        return updated;
      });
      return m;
    }

    // ── Edição normal ─────────────────────────────────────────────────────────
    if (dados.nome && dados.nome.trim().toLowerCase() !== antes.nome.toLowerCase()) {
      const conflito = await prisma.material.findFirst({
        where: { nome: { equals: dados.nome.trim(), mode: 'insensitive' }, id: { not: Number(id) } },
      });
      if (conflito) throw { status: 409, message: `Já existe um material com o nome "${dados.nome}"` };
    }

    const { reativar, ...dadosFiltrados } = dados;
    const { estoqueMinimo = antes.estoqueMinimo, ...rest } = dadosFiltrados;
    const quantidadeAtual = rest.quantidadeAtual ?? antes.quantidadeAtual;
    const status = calcularStatus(quantidadeAtual, estoqueMinimo);

    // Campos que podem ser editados (para o diff)
    const camposComparar = ['nome', 'unidade', 'quantidadeAtual', 'estoqueInicial', 'estoqueMinimo', 'custo', 'ultimoValorPago'];
    const depoisSimulado = { ...antes, ...rest, estoqueMinimo, status };
    const diff = historicoSvc.diffCampos(antes, depoisSimulado, camposComparar);

    const m = await prisma.$transaction(async (tx) => {
      const updated = await tx.material.update({
        where: { id: Number(id) },
        data: { ...rest, estoqueMinimo, status },
      });
      if (diff) {
        await historicoSvc.registrar(Number(id), 'EDICAO', diff, null, tx);
      }
      return updated;
    });

    return m;
  },

  async deletar(id) {
    const material = await prisma.material.findUnique({ where: { id: Number(id) } });
    if (!material) throw { status: 404, message: 'Material não encontrado' };

    return prisma.$transaction(async (tx) => {
      const updated = await tx.material.update({
        where: { id: Number(id) },
        data: { status: 'INATIVO' },
      });
      await tx.fornecedorMaterial.deleteMany({ where: { materialId: Number(id) } });
      await historicoSvc.registrar(Number(id), 'INATIVADO', null, 'Material inativado via exclusão', tx);
      return updated;
    });
  },

  async registrarSaida(id, quantidade, observacoes) {
    const material = await prisma.material.findUnique({ where: { id: Number(id) } });
    if (!material) throw { status: 404, message: 'Material não encontrado' };
    if (material.quantidadeAtual < quantidade) throw { status: 400, message: 'Quantidade insuficiente em estoque' };

    const novaQuantidade = material.quantidadeAtual - quantidade;
    const status = calcularStatus(novaQuantidade, material.estoqueMinimo);

    return prisma.$transaction(async (tx) => {
      const updated = await tx.material.update({
        where: { id: Number(id) },
        data: { quantidadeAtual: novaQuantidade, status },
      });
      await tx.historicoEstoque.create({
        data: {
          materialId: Number(id),
          tipoMovimento: 'SAIDA',
          quantidade,
          quantidadeAntes: material.quantidadeAtual,
          quantidadeDepois: novaQuantidade,
          observacoes,
        },
      });
      await historicoSvc.registrar(
        Number(id), 'SAIDA',
        { quantidadeAtual: { de: material.quantidadeAtual, para: novaQuantidade } },
        observacoes || `Saída de ${quantidade} unidade(s)`,
        tx
      );
      return updated;
    });
  },

  async buscarHistorico(id) {
    return prisma.historicoEstoque.findMany({
      where: { materialId: Number(id) },
      include: { ordemCompra: { select: { numeroOC: true } } },
      orderBy: { createdAt: 'desc' },
    });
  },

  async historicoGeral() {
    return prisma.historicoEstoque.findMany({
      include: {
        material: { select: { id: true, nome: true } },
        ordemCompra: { select: { id: true, numeroOC: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: 200,
    });
  },
};

module.exports = materialService;