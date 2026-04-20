/// Representa uma linha do histórico de estoque originada por uma Ordem de Compra.
/// Mapeado da tabela `HistoricoEstoque` (tipoMovimento == 'ENTRADA') com join de OC.
class HistoricoCompraEntry {
  final int id;
  final int ordemCompraId;
  final int numeroOC;
  final int materialId;
  final String materialNome;
  final String? fornecedorNome;
  final double quantidade;
  final double quantidadeAntes;
  final double quantidadeDepois;
  final double custo;
  final String? observacoes;
  final DateTime data; // createdAt do histórico = data da finalização da OC

  const HistoricoCompraEntry({
    required this.id,
    required this.ordemCompraId,
    required this.numeroOC,
    required this.materialId,
    required this.materialNome,
    this.fornecedorNome,
    required this.quantidade,
    required this.quantidadeAntes,
    required this.quantidadeDepois,
    required this.custo,
    this.observacoes,
    required this.data,
  });

  factory HistoricoCompraEntry.fromJson(Map<String, dynamic> json) {
    return HistoricoCompraEntry(
      id: json['id'] as int,
      ordemCompraId: json['ordemCompraId'] as int,
      numeroOC: json['numeroOC'] is int
          ? json['numeroOC'] as int
          : int.parse(json['numeroOC'].toString()),
      materialId: json['materialId'] as int,
      materialNome: json['materialNome'] as String? ?? 'Material ${json['materialId']}',
      fornecedorNome: json['fornecedorNome'] as String?,
      quantidade: (json['quantidade'] as num).toDouble(),
      quantidadeAntes: (json['quantidadeAntes'] as num).toDouble(),
      quantidadeDepois: (json['quantidadeDepois'] as num).toDouble(),
      custo: (json['custo'] as num).toDouble(),
      observacoes: json['observacoes'] as String?,
      data: DateTime.parse(json['data'] as String),
    );
  }
}