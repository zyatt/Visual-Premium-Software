import 'package:flutter/foundation.dart';
import '../../data/models/historico_material_model.dart';
import '../../data/repositories/historico_material_repository.dart';

class HistoricoMaterialProvider extends ChangeNotifier {
  final _repo = HistoricoMaterialRepository();

  List<HistoricoMaterial> _historico = [];
  bool _loading = false;
  String? _error;
  String? _filtroAcao;

  List<HistoricoMaterial> get historico => _historico;
  bool get loading => _loading;
  String? get error => _error;
  String? get filtroAcao => _filtroAcao;

  void _setLoading(bool v) { _loading = v; notifyListeners(); }
  void _setError(String? v) { _error = v; notifyListeners(); }

  Future<void> carregar({String? acao}) async {
    _filtroAcao = acao;
    _setLoading(true);
    _setError(null);
    try {
      _historico = await _repo.listarGeral(acao: acao);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<List<HistoricoMaterial>> buscarPorMaterial(int id) async {
    return _repo.listarPorMaterial(id);
  }

  void clearError() { _error = null; notifyListeners(); }
}