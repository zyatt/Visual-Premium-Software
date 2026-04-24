/*
  Warnings:

  - You are about to drop the column `fornecedorId` on the `ordem_compra_itens` table. All the data in the column will be lost.
  - Made the column `formaPagamento` on table `ordens_compra` required. This step will fail if there are existing NULL values in that column.

*/
-- CreateEnum
CREATE TYPE "AcaoMaterial" AS ENUM ('CADASTRO', 'EDICAO', 'INATIVADO', 'REATIVADO', 'SAIDA', 'ENTRADA');

-- DropForeignKey
ALTER TABLE "ordem_compra_itens" DROP CONSTRAINT "ordem_compra_itens_fornecedorId_fkey";

-- AlterTable
ALTER TABLE "ordem_compra_itens" DROP COLUMN "fornecedorId";

-- AlterTable
ALTER TABLE "ordens_compra" ALTER COLUMN "formaPagamento" SET NOT NULL;

-- CreateTable
CREATE TABLE "historico_material" (
    "id" SERIAL NOT NULL,
    "materialId" INTEGER NOT NULL,
    "acao" "AcaoMaterial" NOT NULL,
    "camposAlterados" TEXT,
    "observacoes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "historico_material_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "historico_material" ADD CONSTRAINT "historico_material_materialId_fkey" FOREIGN KEY ("materialId") REFERENCES "materiais"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
