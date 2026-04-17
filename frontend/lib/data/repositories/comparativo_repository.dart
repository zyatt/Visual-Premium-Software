import '../../core/utils/api_client.dart';
import '../../core/constants/app_constants.dart';

class ComparativoRepository {
  final _api = ApiClient();

  Future<Map<String, dynamic>> compararMaterial(int materialId) async {
    final data = await _api.get('${AppConstants.comparativoUrl}/material/$materialId');
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> compararPorOrdemCompra(int ordemCompraId) async {
    final data =
        await _api.get('${AppConstants.comparativoUrl}/ordem-compra/$ordemCompraId');
    return data as Map<String, dynamic>;
  }

  Future<List<dynamic>> compararMultiplosMateriais(List<int> materialIds) async {
    final data = await _api.post('${AppConstants.comparativoUrl}/materiais', {
      'materialIds': materialIds,
    });
    return data as List<dynamic>;
  }
}