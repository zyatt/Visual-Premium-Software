/*
  Warnings:

  - You are about to drop the `ordem_compra_itens` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "ordem_compra_itens" DROP CONSTRAINT "ordem_compra_itens_materialId_fkey";

-- DropForeignKey
ALTER TABLE "ordem_compra_itens" DROP CONSTRAINT "ordem_compra_itens_ordemCompraId_fkey";

-- AlterTable
ALTER TABLE "ordens_compra" ALTER COLUMN "formaPagamento" DROP NOT NULL;

-- DropTable
DROP TABLE "ordem_compra_itens";

-- CreateTable
CREATE TABLE "OrdemCompraItem" (
    "id" SERIAL NOT NULL,
    "ordemCompraId" INTEGER NOT NULL,
    "materialId" INTEGER NOT NULL,
    "fornecedorId" INTEGER,
    "quantidade" DOUBLE PRECISION NOT NULL,
    "precoUnitario" DOUBLE PRECISION NOT NULL,
    "precoTotal" DOUBLE PRECISION NOT NULL,
    "prazoEntrega" INTEGER,
    "observacoes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "OrdemCompraItem_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "OrdemCompraItem" ADD CONSTRAINT "OrdemCompraItem_ordemCompraId_fkey" FOREIGN KEY ("ordemCompraId") REFERENCES "ordens_compra"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OrdemCompraItem" ADD CONSTRAINT "OrdemCompraItem_materialId_fkey" FOREIGN KEY ("materialId") REFERENCES "materiais"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OrdemCompraItem" ADD CONSTRAINT "OrdemCompraItem_fornecedorId_fkey" FOREIGN KEY ("fornecedorId") REFERENCES "fornecedores"("id") ON DELETE SET NULL ON UPDATE CASCADE;
