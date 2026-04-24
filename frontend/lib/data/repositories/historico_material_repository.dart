import '../models/historico_material_model.dart';
import '../../core/utils/api_client.dart';
import '../../core/constants/app_constants.dart';

class HistoricoMaterialRepository {
  final _api = ApiClient();

  Future<List<HistoricoMaterial>> listarGeral({String? acao, int page = 1, int limit = 200}) async {
    final params = <String, String>{'page': '$page', 'limit': '$limit'};
    if (acao != null) params['acao'] = acao;
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final data = await _api.get('${AppConstants.historicoMaterialUrl}?$query');
    return (data as List).map((e) => HistoricoMaterial.fromJson(e)).toList();
  }

  Future<List<HistoricoMaterial>> listarPorMaterial(int materialId) async {
    final data = await _api.get('${AppConstants.historicoMaterialUrl}/material/$materialId');
    return (data as List).map((e) => HistoricoMaterial.fromJson(e)).toList();
  }
}