/*
  Warnings:

  - A unique constraint covering the columns `[nome]` on the table `materiais` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateIndex
CREATE UNIQUE INDEX "materiais_nome_key" ON "materiais"("nome");
