require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });
const prisma = require('../utils/prisma');

async function main() {
  const materiais = await prisma.material.findMany();
  
  for (const m of materiais) {
    await prisma.historicoMaterial.create({
      data: {
        materialId: m.id,
        acao: 'CADASTRO',
        observacoes: 'Registro inicial (migração)',
        createdAt: m.createdAt,
      },
    });
  }

  console.log(`✅ ${materiais.length} registros inseridos`);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());