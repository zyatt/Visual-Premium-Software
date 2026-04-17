class HistoricoEstoque {
  final int id;
  final int materialId;
  final int? ordemCompraId;
  final String tipoMovimento;
  final double quantidade;
  final double quantidadeAntes;
  final double quantidadeDepois;
  final double? custo;
  final String? observacoes;
  final DateTime createdAt;
  final Map<String, dynamic>? material;
  final Map<String, dynamic>? ordemCompra;

  const HistoricoEstoque({
    required this.id,
    required this.materialId,
    this.ordemCompraId,
    required this.tipoMovimento,
    required this.quantidade,
    required this.quantidadeAntes,
    required this.quantidadeDepois,
    this.custo,
    this.observacoes,
    required this.createdAt,
    this.material,
    this.ordemCompra,
  });

  factory HistoricoEstoque.fromJson(Map<String, dynamic> json) => HistoricoEstoque(
    id: json['id'],
    materialId: json['materialId'],
    ordemCompraId: json['ordemCompraId'],
    tipoMovimento: json['tipoMovimento'],
    quantidade: (json['quantidade'] as num).toDouble(),
    quantidadeAntes: (json['quantidadeAntes'] as num).toDouble(),
    quantidadeDepois: (json['quantidadeDepois'] as num).toDouble(),
    custo: json['custo'] != null ? (json['custo'] as num).toDouble() : null,
    observacoes: json['observacoes'],
    createdAt: DateTime.parse(json['createdAt']),
    material: json['material'],
    ordemCompra: json['ordemCompra'],
  );
}