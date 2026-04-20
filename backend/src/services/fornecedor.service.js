const prisma = require('../utils/prisma');

const fornecedorService = {
  async listarTodos() {
    return prisma.fornecedor.findMany({
      include: {
        materiais: {
          where: {
            material: { status: { not: 'INATIVO' } },
          },
          include: { material: true },
        },
      },
      orderBy: { nome: 'asc' },
    });
  },

  async buscarPorId(id) {
    const fornecedor = await prisma.fornecedor.findUnique({
      where: { id: Number(id) },
      include: {
        materiais: {
          where: {
            material: { status: { not: 'INATIVO' } },
          },
          include: { material: true },
        },
      },
    });
    if (!fornecedor) throw { status: 404, message: 'Fornecedor não encontrado' };
    return fornecedor;
  },

  async criar(dados) {
    const { nome, tipoFornecedor, telefone, razaoSocial, nomeFantasia, cnpj } = dados;
    return prisma.fornecedor.create({
      data: { nome, tipoFornecedor, telefone, razaoSocial, nomeFantasia, cnpj },
    });
  },

  async atualizar(id, dados) {
    const existe = await prisma.fornecedor.findUnique({ where: { id: Number(id) } });
    if (!existe) throw { status: 404, message: 'Fornecedor não encontrado' };
    const { nome, tipoFornecedor, telefone, razaoSocial, nomeFantasia, cnpj } = dados;
    return prisma.fornecedor.update({
      where: { id: Number(id) },
      data: { nome, tipoFornecedor, telefone, razaoSocial, nomeFantasia, cnpj },
    });
  },

  async deletar(id) {
    const existe = await prisma.fornecedor.findUnique({ where: { id: Number(id) } });
    if (!existe) throw { status: 404, message: 'Fornecedor não encontrado' };
    return prisma.fornecedor.delete({ where: { id: Number(id) } });
  },

  async adicionarMaterial(fornecedorId, materialId, custo, prazoEntrega) {
    // Verificar se fornecedor e material existem
    const [fornecedor, material] = await Promise.all([
      prisma.fornecedor.findUnique({ where: { id: Number(fornecedorId) } }),
      prisma.material.findUnique({ where: { id: Number(materialId) } }),
    ]);
    if (!fornecedor) throw { status: 404, message: 'Fornecedor não encontrado' };
    if (!material) throw { status: 404, message: 'Material não encontrado' };

    return prisma.fornecedorMaterial.upsert({
      where: {
        fornecedorId_materialId: {
          fornecedorId: Number(fornecedorId),
          materialId: Number(materialId),
        },
      },
      create: {
        fornecedorId: Number(fornecedorId),
        materialId: Number(materialId),
        custo,
        prazoEntrega,
      },
      update: { custo, prazoEntrega },
    });
  },

  async removerMaterial(fornecedorId, materialId) {
    return prisma.fornecedorMaterial.delete({
      where: {
        fornecedorId_materialId: {
          fornecedorId: Number(fornecedorId),
          materialId: Number(materialId),
        },
      },
    });
  },
};

module.exports = fornecedorService;