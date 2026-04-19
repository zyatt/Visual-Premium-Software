const prisma = require('../utils/prisma');

const calcularStatus = (quantidadeAtual, estoqueMinimo) => {
  if (quantidadeAtual <= 0) return 'CRITICO';
  if (quantidadeAtual <= estoqueMinimo) return 'BAIXO';
  return 'OK';
};

const materialService = {
  async listarTodos() {
    return prisma.material.findMany({
      include: {
        fornecedorMateriais: {
          include: { fornecedor: true },
        },
      },
      orderBy: { nome: 'asc' },
    });
  },

  async buscarPorId(id) {
    const material = await prisma.material.findUnique({
      where: { id: Number(id) },
      include: {
        fornecedorMateriais: {
          include: { fornecedor: true },
        },
        historicoEstoque: {
          orderBy: { createdAt: 'desc' },
          take: 50,
        },
      },
    });
    if (!material) throw { status: 404, message: 'Material não encontrado' };
    return material;
  },

  async criar(dados) {
    const { nome, quantidadeAtual = 0, estoqueInicial = 0, estoqueMinimo = 0, custo = 0 } = dados;

    const existente = await prisma.material.findFirst({
      where: { nome: { equals: nome.trim(), mode: 'insensitive' } },
    });
    if (existente) {
      throw { status: 409, message: `Já existe um material cadastrado com o nome "${nome}"` };
    }

    const status = calcularStatus(quantidadeAtual, estoqueMinimo);

    const material = await prisma.material.create({
      data: {
        nome,
        quantidadeAtual,
        estoqueInicial,
        estoqueMinimo,
        custo,
        status,
      },
    });

    // Registrar entrada inicial se houver
    if (estoqueInicial > 0) {
      await prisma.historicoEstoque.create({
        data: {
          materialId: material.id,
          tipoMovimento: 'ENTRADA',
          quantidade: estoqueInicial,
          quantidadeAntes: 0,
          quantidadeDepois: estoqueInicial,
          custo,
          observacoes: 'Estoque inicial',
        },
      });
    }

    return material;
  },

  async atualizar(id, dados) {
    const materialExistente = await prisma.material.findUnique({ where: { id: Number(id) } });
    if (!materialExistente) throw { status: 404, message: 'Material não encontrado' };

    if (dados.nome && dados.nome.trim().toLowerCase() !== materialExistente.nome.toLowerCase()) {
      const conflito = await prisma.material.findFirst({
        where: {
          nome: { equals: dados.nome.trim(), mode: 'insensitive' },
          id: { not: Number(id) },
        },
      });
      if (conflito) {
        throw { status: 409, message: `Já existe um material cadastrado com o nome "${dados.nome}"` };
      }
    }

    const { estoqueMinimo = materialExistente.estoqueMinimo, ...rest } = dados;
    const quantidadeAtual = rest.quantidadeAtual ?? materialExistente.quantidadeAtual;
    const status = calcularStatus(quantidadeAtual, estoqueMinimo);

    return prisma.material.update({
      where: { id: Number(id) },
      data: { ...rest, estoqueMinimo, status },
    });
  },

  async deletar(id) {
    await prisma.material.findUnique({ where: { id: Number(id) } }) ||
      (() => { throw { status: 404, message: 'Material não encontrado' }; })();
    return prisma.material.delete({ where: { id: Number(id) } });
  },

  async registrarSaida(id, quantidade, observacoes) {
    const material = await prisma.material.findUnique({ where: { id: Number(id) } });
    if (!material) throw { status: 404, message: 'Material não encontrado' };
    if (material.quantidadeAtual < quantidade) {
      throw { status: 400, message: 'Quantidade insuficiente em estoque' };
    }

    const novaQuantidade = material.quantidadeAtual - quantidade;
    const status = calcularStatus(novaQuantidade, material.estoqueMinimo);

    const [materialAtualizado] = await prisma.$transaction([
      prisma.material.update({
        where: { id: Number(id) },
        data: { quantidadeAtual: novaQuantidade, status },
      }),
      prisma.historicoEstoque.create({
        data: {
          materialId: Number(id),
          tipoMovimento: 'SAIDA',
          quantidade,
          quantidadeAntes: material.quantidadeAtual,
          quantidadeDepois: novaQuantidade,
          observacoes,
        },
      }),
    ]);

    return materialAtualizado;
  },

  async buscarHistorico(id) {
    return prisma.historicoEstoque.findMany({
      where: { materialId: Number(id) },
      include: {
        ordemCompra: { select: { numeroOC: true } },
      },
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