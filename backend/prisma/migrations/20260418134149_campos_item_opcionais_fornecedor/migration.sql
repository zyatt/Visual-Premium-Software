-- DropForeignKey
ALTER TABLE "ordens_compra" DROP CONSTRAINT "ordens_compra_fornecedorId_fkey";

-- AlterTable
ALTER TABLE "ordem_compra_itens" ADD COLUMN     "fornecedorId" INTEGER;

-- AlterTable
ALTER TABLE "ordens_compra" ALTER COLUMN "formaPagamento" DROP NOT NULL,
ALTER COLUMN "fornecedorId" DROP NOT NULL;

-- AddForeignKey
ALTER TABLE "ordens_compra" ADD CONSTRAINT "ordens_compra_fornecedorId_fkey" FOREIGN KEY ("fornecedorId") REFERENCES "fornecedores"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ordem_compra_itens" ADD CONSTRAINT "ordem_compra_itens_fornecedorId_fkey" FOREIGN KEY ("fornecedorId") REFERENCES "fornecedores"("id") ON DELETE SET NULL ON UPDATE CASCADE;
