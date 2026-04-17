import '../models/material_model.dart';
import '../models/historico_model.dart';
import '../../core/utils/api_client.dart';
import '../../core/constants/app_constants.dart';

class MaterialRepository {
  final _api = ApiClient();

  Future<List<MaterialModel>> listarTodos() async {
    final data = await _api.get(AppConstants.materiaisUrl);
    return (data as List).map((e) => MaterialModel.fromJson(e)).toList();
  }

  Future<MaterialModel> buscarPorId(int id) async {
    final data = await _api.get('${AppConstants.materiaisUrl}/$id');
    return MaterialModel.fromJson(data);
  }

  Future<MaterialModel> criar(Map<String, dynamic> dados) async {
    final data = await _api.post(AppConstants.materiaisUrl, dados);
    return MaterialModel.fromJson(data);
  }

  Future<MaterialModel> atualizar(int id, Map<String, dynamic> dados) async {
    final data = await _api.put('${AppConstants.materiaisUrl}/$id', dados);
    return MaterialModel.fromJson(data);
  }

  Future<void> deletar(int id) async {
    await _api.delete('${AppConstants.materiaisUrl}/$id');
  }

  Future<MaterialModel> registrarSaida(int id, double quantidade, String? observacoes) async {
    final data = await _api.post('${AppConstants.materiaisUrl}/$id/saida', {
      'quantidade': quantidade,
      if (observacoes != null) 'observacoes': observacoes,
    });
    return MaterialModel.fromJson(data);
  }

  Future<List<HistoricoEstoque>> buscarHistorico(int id) async {
    final data = await _api.get('${AppConstants.materiaisUrl}/$id/historico');
    return (data as List).map((e) => HistoricoEstoque.fromJson(e)).toList();
  }

  Future<List<HistoricoEstoque>> historicoGeral() async {
    final data = await _api.get('${AppConstants.materiaisUrl}/historico');
    return (data as List).map((e) => HistoricoEstoque.fromJson(e)).toList();
  }
}