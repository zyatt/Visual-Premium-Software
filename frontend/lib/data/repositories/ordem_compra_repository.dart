import '../models/ordem_compra_model.dart';
import '../../core/utils/api_client.dart';
import '../../core/constants/app_constants.dart';

class OrdemCompraRepository {
  final _api = ApiClient();

  Future<List<OrdemCompra>> listarTodos() async {
    final data = await _api.get(AppConstants.ordensCompraUrl);
    return (data as List).map((e) => OrdemCompra.fromJson(e)).toList();
  }

  Future<OrdemCompra> buscarPorId(int id) async {
    final data = await _api.get('${AppConstants.ordensCompraUrl}/$id');
    return OrdemCompra.fromJson(data);
  }

  Future<OrdemCompra> criar(Map<String, dynamic> dados) async {
    final data = await _api.post(AppConstants.ordensCompraUrl, dados);
    return OrdemCompra.fromJson(data);
  }

  Future<OrdemCompra> atualizar(int id, Map<String, dynamic> dados) async {
    final data = await _api.put('${AppConstants.ordensCompraUrl}/$id', dados);
    return OrdemCompra.fromJson(data);
  }

  Future<OrdemCompra> cancelar(int id) async {
    final data = await _api.patch('${AppConstants.ordensCompraUrl}/$id/cancelar');
    return OrdemCompra.fromJson(data);
  }

  Future<OrdemCompra> finalizar(int id) async {
    final data = await _api.patch('${AppConstants.ordensCompraUrl}/$id/finalizar');
    return OrdemCompra.fromJson(data);
  }

  Future<OrdemCompraItem> adicionarItem(int ordemId, Map<String, dynamic> item) async {
    final data = await _api.post('${AppConstants.ordensCompraUrl}/$ordemId/itens', item);
    return OrdemCompraItem.fromJson(data);
  }

  Future<void> removerItem(int ordemId, int itemId) async {
    await _api.delete('${AppConstants.ordensCompraUrl}/$ordemId/itens/$itemId');
  }
}