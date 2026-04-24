require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { errorHandler } = require('./middlewares/errorHandler');

const materialRoutes = require('./routes/material.routes');
const fornecedorRoutes = require('./routes/fornecedor.routes');
const ordemCompraRoutes = require('./routes/ordemCompra.routes');
const estoqueRoutes = require('./routes/estoque.routes');
const comparativoRoutes = require('./routes/comparativo.routes');
const historicoMaterialRoutes = require('./routes/historicoMaterial.routes');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Rotas
app.use('/api/materiais', materialRoutes);
app.use('/api/fornecedores', fornecedorRoutes);
app.use('/api/ordens-compra', ordemCompraRoutes);
app.use('/api/estoque', estoqueRoutes);
app.use('/api/comparativo', comparativoRoutes);
app.use('/api/historico-material', historicoMaterialRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Error handler global
app.use(errorHandler);

app.listen(PORT, () => {
  console.log(`🚀 Servidor rodando na porta ${PORT}`);
});

module.exports = app;