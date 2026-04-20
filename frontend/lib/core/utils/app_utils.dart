import 'package:intl/intl.dart';

class AppUtils {
  static final _currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final _dateFormatter = DateFormat('dd/MM/yyyy');
  static final _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');
  static final _numberFormatter = NumberFormat('#,##0.##', 'pt_BR');

  static String formatCurrency(double value) => _currencyFormatter.format(value);

  static String formatDate(DateTime date) => _dateFormatter.format(date);

  static String formatDateTime(DateTime date) => _dateTimeFormatter.format(date);

  static String formatNumber(double value) => _numberFormatter.format(value);

  static String formatPrazo(int? dias) {
    if (dias == null) return '-';
    if (dias == 1) return '1 dia';
    return '$dias dias';
  }

  static String labelStatusMaterial(String status) {
    switch (status) {
      case 'OK': return 'Ok';
      case 'BAIXO': return 'Baixo';
      case 'CRITICO': return 'Crítico';
      case 'INATIVO': return 'Inativo';
      default: return status;
    }
  }

  static String labelStatusOC(String status) {
    switch (status) {
      case 'EM_ANDAMENTO': return 'Em Andamento';
      case 'FINALIZADO': return 'Finalizado';
      case 'CANCELADO': return 'Cancelado';
      default: return status;
    }
  }
}