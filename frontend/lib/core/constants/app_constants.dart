class AppConstants {
  static const String baseUrl = 'http://localhost:3000/api';
  static const String materiaisUrl = '$baseUrl/materiais';
  static const String fornecedoresUrl = '$baseUrl/fornecedores';
  static const String ordensCompraUrl = '$baseUrl/ordens-compra';
  static const String estoqueUrl = '$baseUrl/estoque';
  static const String comparativoUrl = '$baseUrl/comparativo';

  static const Duration requestTimeout = Duration(seconds: 15);

  // Status Material
  static const String statusOk = 'OK';
  static const String statusBaixo = 'BAIXO';
  static const String statusCritico = 'CRITICO';

  // Status OC
  static const String ocEmAndamento = 'EM_ANDAMENTO';
  static const String ocFinalizado = 'FINALIZADO';
  static const String ocCancelado = 'CANCELADO';
}