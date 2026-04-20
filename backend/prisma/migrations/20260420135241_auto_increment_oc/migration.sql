/*
  Warnings:

  - The `numeroOC` column on the `ordens_compra` table would be dropped and recreated. This will lead to data loss if there is data in the column.

*/
-- AlterTable
ALTER TABLE "ordens_compra" DROP COLUMN "numeroOC",
ADD COLUMN     "numeroOC" SERIAL NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "ordens_compra_numeroOC_key" ON "ordens_compra"("numeroOC");
