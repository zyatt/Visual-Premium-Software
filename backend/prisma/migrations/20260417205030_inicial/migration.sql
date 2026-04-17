-- CreateEnum
CREATE TYPE "StatusMaterial" AS ENUM ('OK', 'BAIXO', 'CRITICO');

-- CreateEnum
CREATE TYPE "StatusOC" AS ENUM ('EM_ANDAMENTO', 'FINALIZADO', 'CANCELADO');

-- CreateEnum
CREATE TYPE "TipoMovimento" AS ENUM ('ENTRADA', 'SAIDA');

-- CreateTable
CREATE TABLE "materiais" (
    "id" SERIAL NOT NULL,
    "nome" TEXT NOT NULL,
    "quantidadeAtual" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "estoqueInicial" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "estoqueMinimo" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "custo" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "ultimoValorPago" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "status" "StatusMaterial" NOT NULL DEFAULT 'OK',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "materiais_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "fornecedores" (
    "id" SERIAL NOT NULL,
    "nome" TEXT NOT NULL,
    "tipoFornecedor" TEXT,
    "telefone" TEXT,
    "razaoSocial" TEXT,
    "nomeFantasia" TEXT,
    "cnpj" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "fornecedores_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "fornecedor_materiais" (
    "id" SERIAL NOT NULL,
    "fornecedorId" INTEGER NOT NULL,
    "materialId" INTEGER NOT NULL,
    "custo" DOUBLE PRECISION NOT NULL,
    "prazoEntrega" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "fornecedor_materiais_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ordens_compra" (
    "id" SERIAL NOT NULL,
    "numeroOC" TEXT NOT NULL,
    "data" TIMESTAMP(3) NOT NULL,
    "formaPagamento" TEXT NOT NULL,
    "fornecedorId" INTEGER NOT NULL,
    "observacoes" TEXT,
    "status" "StatusOC" NOT NULL DEFAULT 'EM_ANDAMENTO',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ordens_compra_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ordem_compra_itens" (
    "id" SERIAL NOT NULL,
    "ordemCompraId" INTEGER NOT NULL,
    "materialId" INTEGER NOT NULL,
    "quantidade" DOUBLE PRECISION NOT NULL,
    "precoUnitario" DOUBLE PRECISION NOT NULL,
    "precoTotal" DOUBLE PRECISION NOT NULL,
    "prazoEntrega" INTEGER,
    "observacoes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ordem_compra_itens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "historico_estoque" (
    "id" SERIAL NOT NULL,
    "materialId" INTEGER NOT NULL,
    "ordemCompraId" INTEGER,
    "tipoMovimento" "TipoMovimento" NOT NULL,
    "quantidade" DOUBLE PRECISION NOT NULL,
    "quantidadeAntes" DOUBLE PRECISION NOT NULL,
    "quantidadeDepois" DOUBLE PRECISION NOT NULL,
    "custo" DOUBLE PRECISION,
    "observacoes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "historico_estoque_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "fornecedor_materiais_fornecedorId_materialId_key" ON "fornecedor_materiais"("fornecedorId", "materialId");

-- CreateIndex
CREATE UNIQUE INDEX "ordens_compra_numeroOC_key" ON "ordens_compra"("numeroOC");

-- AddForeignKey
ALTER TABLE "fornecedor_materiais" ADD CONSTRAINT "fornecedor_materiais_fornecedorId_fkey" FOREIGN KEY ("fornecedorId") REFERENCES "fornecedores"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fornecedor_materiais" ADD CONSTRAINT "fornecedor_materiais_materialId_fkey" FOREIGN KEY ("materialId") REFERENCES "materiais"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ordens_compra" ADD CONSTRAINT "ordens_compra_fornecedorId_fkey" FOREIGN KEY ("fornecedorId") REFERENCES "fornecedores"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ordem_compra_itens" ADD CONSTRAINT "ordem_compra_itens_ordemCompraId_fkey" FOREIGN KEY ("ordemCompraId") REFERENCES "ordens_compra"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ordem_compra_itens" ADD CONSTRAINT "ordem_compra_itens_materialId_fkey" FOREIGN KEY ("materialId") REFERENCES "materiais"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "historico_estoque" ADD CONSTRAINT "historico_estoque_materialId_fkey" FOREIGN KEY ("materialId") REFERENCES "materiais"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "historico_estoque" ADD CONSTRAINT "historico_estoque_ordemCompraId_fkey" FOREIGN KEY ("ordemCompraId") REFERENCES "ordens_compra"("id") ON DELETE SET NULL ON UPDATE CASCADE;
