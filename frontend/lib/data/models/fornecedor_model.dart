import 'material_model.dart';

class FornecedorMaterial {
  final int id;
  final int fornecedorId;
  final int materialId;
  final double custo;
  final int? prazoEntrega;
  final MaterialModel? material;

  const FornecedorMaterial({
    required this.id,
    required this.fornecedorId,
    required this.materialId,
    required this.custo,
    this.prazoEntrega,
    this.material,
  });

  factory FornecedorMaterial.fromJson(Map<String, dynamic> json) => FornecedorMaterial(
    id: json['id'],
    fornecedorId: json['fornecedorId'],
    materialId: json['materialId'],
    custo: (json['custo'] as num).toDouble(),
    prazoEntrega: json['prazoEntrega'],
    material: json['material'] != null ? MaterialModel.fromJson(json['material']) : null,
  );
}

class Fornecedor {
  final int id;
  final String nome;
  final String? tipoFornecedor;
  final String? telefone;
  final String? razaoSocial;
  final String? nomeFantasia;
  final String? cnpj;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<FornecedorMaterial> materiais;

  const Fornecedor({
    required this.id,
    required this.nome,
    this.tipoFornecedor,
    this.telefone,
    this.razaoSocial,
    this.nomeFantasia,
    this.cnpj,
    required this.createdAt,
    required this.updatedAt,
    this.materiais = const [],
  });

  factory Fornecedor.fromJson(Map<String, dynamic> json) => Fornecedor(
    id: json['id'],
    nome: json['nome'],
    tipoFornecedor: json['tipoFornecedor'],
    telefone: json['telefone'],
    razaoSocial: json['razaoSocial'],
    nomeFantasia: json['nomeFantasia'],
    cnpj: json['cnpj'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    materiais: (json['materiais'] as List<dynamic>?)
            ?.map((m) => FornecedorMaterial.fromJson(m))
            .toList() ??
        [],
  );

  Map<String, dynamic> toJson() => {
    'nome': nome,
    if (tipoFornecedor != null) 'tipoFornecedor': tipoFornecedor,
    if (telefone != null) 'telefone': telefone,
    if (razaoSocial != null) 'razaoSocial': razaoSocial,
    if (nomeFantasia != null) 'nomeFantasia': nomeFantasia,
    if (cnpj != null) 'cnpj': cnpj,
  };

  Fornecedor copyWith({
    int? id, String? nome, String? tipoFornecedor, String? telefone,
    String? razaoSocial, String? nomeFantasia, String? cnpj,
    DateTime? createdAt, DateTime? updatedAt, List<FornecedorMaterial>? materiais,
  }) => Fornecedor(
    id: id ?? this.id,
    nome: nome ?? this.nome,
    tipoFornecedor: tipoFornecedor ?? this.tipoFornecedor,
    telefone: telefone ?? this.telefone,
    razaoSocial: razaoSocial ?? this.razaoSocial,
    nomeFantasia: nomeFantasia ?? this.nomeFantasia,
    cnpj: cnpj ?? this.cnpj,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    materiais: materiais ?? this.materiais,
  );
}