import 'dart:convert';

class HistoricoMaterial {
  final int id;
  final int materialId;
  final String acao;
  final Map<String, dynamic>? camposAlterados;
  final String? observacoes;
  final DateTime createdAt;
  final Map<String, dynamic>? material;

  const HistoricoMaterial({
    required this.id,
    required this.materialId,
    required this.acao,
    this.camposAlterados,
    this.observacoes,
    required this.createdAt,
    this.material,
  });

  factory HistoricoMaterial.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? campos;
    if (json['camposAlterados'] != null) {
      try {
        if (json['camposAlterados'] is String) {
          campos = jsonDecode(json['camposAlterados'] as String) as Map<String, dynamic>;
        } else {
          campos = json['camposAlterados'] as Map<String, dynamic>;
        }
      } catch (_) {}
    }
    return HistoricoMaterial(
      id: json['id'] as int,
      materialId: json['materialId'] as int,
      acao: json['acao'] as String,
      camposAlterados: campos,
      observacoes: json['observacoes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      material: json['material'] as Map<String, dynamic>?,
    );
  }
}