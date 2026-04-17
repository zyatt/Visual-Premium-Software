const errorHandler = (err, req, res, next) => {
  console.error(err.stack);

  if (err.code === 'P2002') {
    return res.status(409).json({
      error: 'Registro duplicado',
      message: `Já existe um registro com este valor único`,
    });
  }

  if (err.code === 'P2025') {
    return res.status(404).json({
      error: 'Não encontrado',
      message: 'Registro não encontrado',
    });
  }

  res.status(err.status || 500).json({
    error: err.message || 'Erro interno do servidor',
    message: err.details || 'Ocorreu um erro inesperado',
  });
};

const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

module.exports = { errorHandler, asyncHandler };