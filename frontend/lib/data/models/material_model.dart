class MaterialModel  {
  final int id;
  final String nome;
  final double quantidadeAtual;
  final double estoqueInicial;
  final double estoqueMinimo;
  final double custo;
  final double ultimoValorPago;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MaterialModel ({
    required this.id,
    required this.nome,
    required this.quantidadeAtual,
    required this.estoqueInicial,
    required this.estoqueMinimo,
    required this.custo,
    required this.ultimoValorPago,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  double get saldo => quantidadeAtual - estoqueInicial;

  factory MaterialModel.fromJson(Map<String, dynamic> json) => MaterialModel(
    id: json['id'],
    nome: json['nome'],
    quantidadeAtual: (json['quantidadeAtual'] as num).toDouble(),
    estoqueInicial: (json['estoqueInicial'] as num).toDouble(),
    estoqueMinimo: (json['estoqueMinimo'] as num).toDouble(),
    custo: (json['custo'] as num).toDouble(),
    ultimoValorPago: (json['ultimoValorPago'] as num).toDouble(),
    status: json['status'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'quantidadeAtual': quantidadeAtual,
    'estoqueInicial': estoqueInicial,
    'estoqueMinimo': estoqueMinimo,
    'custo': custo,
    'ultimoValorPago': ultimoValorPago,
  };

  MaterialModel copyWith({
    int? id, String? nome, double? quantidadeAtual, double? estoqueInicial,
    double? estoqueMinimo, double? custo, double? ultimoValorPago,
    String? status, DateTime? createdAt, DateTime? updatedAt,
  }) => MaterialModel(
    id: id ?? this.id,
    nome: nome ?? this.nome,
    quantidadeAtual: quantidadeAtual ?? this.quantidadeAtual,
    estoqueInicial: estoqueInicial ?? this.estoqueInicial,
    estoqueMinimo: estoqueMinimo ?? this.estoqueMinimo,
    custo: custo ?? this.custo,
    ultimoValorPago: ultimoValorPago ?? this.ultimoValorPago,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}