import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static String get _host => dotenv.env['API_HOST'] ?? 'localhost';
  static String get _port => dotenv.env['API_PORT'] ?? '3000';

  static String get baseUrl => 'http://$_host:$_port/api';
  static String get materiaisUrl => '$baseUrl/materiais';
  static String get fornecedoresUrl => '$baseUrl/fornecedores';
  static String get ordensCompraUrl => '$baseUrl/ordens-compra';
  static String get estoqueUrl => '$baseUrl/estoque';
  static String get comparativoUrl => '$baseUrl/comparativo';

  static const Duration requestTimeout = Duration(seconds: 15);

  // Status Material
  static const String statusOk = 'OK';
  static const String statusBaixo = 'BAIXO';
  static const String statusCritico = 'CRITICO';
  static const String statusInativo = 'INATIVO';

  // Status OC
  static const String ocEmAndamento = 'EM_ANDAMENTO';
  static const String ocFinalizado = 'FINALIZADO';
  static const String ocCancelado = 'CANCELADO';
}