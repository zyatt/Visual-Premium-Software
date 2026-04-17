import '../models/fornecedor_model.dart';
import '../../core/utils/api_client.dart';
import '../../core/constants/app_constants.dart';

class FornecedorRepository {
  final _api = ApiClient();

  Future<List<Fornecedor>> listarTodos() async {
    final data = await _api.get(AppConstants.fornecedoresUrl);
    return (data as List).map((e) => Fornecedor.fromJson(e)).toList();
  }

  Future<Fornecedor> buscarPorId(int id) async {
    final data = await _api.get('${AppConstants.fornecedoresUrl}/$id');
    return Fornecedor.fromJson(data);
  }

  Future<Fornecedor> criar(Map<String, dynamic> dados) async {
    final data = await _api.post(AppConstants.fornecedoresUrl, dados);
    return Fornecedor.fromJson(data);
  }

  Future<Fornecedor> atualizar(int id, Map<String, dynamic> dados) async {
    final data = await _api.put('${AppConstants.fornecedoresUrl}/$id', dados);
    return Fornecedor.fromJson(data);
  }

  Future<void> deletar(int id) async {
    await _api.delete('${AppConstants.fornecedoresUrl}/$id');
  }

  Future<FornecedorMaterial> adicionarMaterial(
      int fornecedorId, int materialId, double custo, int? prazoEntrega) async {
    final data = await _api.post('${AppConstants.fornecedoresUrl}/$fornecedorId/materiais', {
      'materialId': materialId,
      'custo': custo,
      if (prazoEntrega != null) 'prazoEntrega': prazoEntrega,
    });
    return FornecedorMaterial.fromJson(data);
  }

  Future<void> removerMaterial(int fornecedorId, int materialId) async {
    await _api.delete('${AppConstants.fornecedoresUrl}/$fornecedorId/materiais/$materialId');
  }
}