import 'material_model.dart';
import 'fornecedor_model.dart';

class OrdemCompraItem {
  final int id;
  final int ordemCompraId;
  final int materialId;
  final double quantidade;
  final double precoUnitario;
  final double precoTotal;
  final int? prazoEntrega;
  final String? observacoes;
  final MaterialModel? material;

  const OrdemCompraItem({
    required this.id,
    required this.ordemCompraId,
    required this.materialId,
    required this.quantidade,
    required this.precoUnitario,
    required this.precoTotal,
    this.prazoEntrega,
    this.observacoes,
    this.material,
  });

  factory OrdemCompraItem.fromJson(Map<String, dynamic> json) => OrdemCompraItem(
    id: json['id'],
    ordemCompraId: json['ordemCompraId'],
    materialId: json['materialId'],
    quantidade: (json['quantidade'] as num).toDouble(),
    precoUnitario: (json['precoUnitario'] as num).toDouble(),
    precoTotal: (json['precoTotal'] as num).toDouble(),
    prazoEntrega: json['prazoEntrega'],
    observacoes: json['observacoes'],
    material: json['material'] != null ? MaterialModel.fromJson(json['material']) : null,
  );

  Map<String, dynamic> toJson() => {
    'materialId': materialId,
    'quantidade': quantidade,
    'precoUnitario': precoUnitario,
    'precoTotal': precoTotal,
    if (prazoEntrega != null) 'prazoEntrega': prazoEntrega,
    if (observacoes != null) 'observacoes': observacoes,
  };
}

class OrdemCompra {
  final int id;
  final String numeroOC;
  final DateTime data;
  final String formaPagamento;
  final int fornecedorId;
  final String? observacoes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Fornecedor? fornecedor;
  final List<OrdemCompraItem> itens;

  const OrdemCompra({
    required this.id,
    required this.numeroOC,
    required this.data,
    required this.formaPagamento,
    required this.fornecedorId,
    this.observacoes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.fornecedor,
    this.itens = const [],
  });

  double get valorTotal => itens.fold(0, (sum, item) => sum + item.precoTotal);

  factory OrdemCompra.fromJson(Map<String, dynamic> json) => OrdemCompra(
    id: json['id'],
    numeroOC: json['numeroOC'],
    data: DateTime.parse(json['data']),
    formaPagamento: json['formaPagamento'],
    fornecedorId: json['fornecedorId'],
    observacoes: json['observacoes'],
    status: json['status'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    fornecedor: json['fornecedor'] != null ? Fornecedor.fromJson(json['fornecedor']) : null,
    itens: (json['itens'] as List<dynamic>?)
            ?.map((i) => OrdemCompraItem.fromJson(i))
            .toList() ??
        [],
  );

  Map<String, dynamic> toJson() => {
    'numeroOC': numeroOC,
    'data': data.toIso8601String(),
    'formaPagamento': formaPagamento,
    'fornecedorId': fornecedorId,
    if (observacoes != null) 'observacoes': observacoes,
  };
}