import 'package:flutter/foundation.dart';
import '../../data/models/material_model.dart';
import '../../data/models/historico_model.dart';
import '../../data/repositories/material_repository.dart';

class MaterialProvider extends ChangeNotifier {
  final _repo = MaterialRepository();

  List<MaterialModel> _materiais = [];
  List<HistoricoEstoque> _historico = [];
  bool _loading = false;
  String? _error;

  List<MaterialModel> get materiais => _materiais;
  List<MaterialModel> get materiaisAtivos =>           // <-- ADICIONADO
      _materiais.where((m) => m.status != 'INATIVO').toList();
  List<HistoricoEstoque> get historico => _historico;
  bool get loading => _loading;
  String? get error => _error;

  int get totalMateriais => _materiais.length;
  int get totalOk => _materiais.where((m) => m.status == 'OK').length;
  int get totalBaixo => _materiais.where((m) => m.status == 'BAIXO').length;
  int get totalCritico => _materiais.where((m) => m.status == 'CRITICO').length;

  void _setLoading(bool v) { _loading = v; notifyListeners(); }
  void _setError(String? v) { _error = v; notifyListeners(); }

  Future<void> carregarMateriais() async {
    _setLoading(true);
    _setError(null);
    try {
      _materiais = await _repo.listarTodos();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<MaterialModel?> criar(Map<String, dynamic> dados) async {
    try {
      final m = await _repo.criar(dados);
      _materiais.add(m);
      notifyListeners();
      return m;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  Future<MaterialModel?> atualizar(int id, Map<String, dynamic> dados) async {
    try {
      final m = await _repo.atualizar(id, dados);
      final idx = _materiais.indexWhere((x) => x.id == id);
      if (idx != -1) _materiais[idx] = m;
      notifyListeners();
      return m;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  Future<bool> deletar(int id) async {
    try {
      await _repo.deletar(id);
      _materiais.removeWhere((m) => m.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<MaterialModel?> registrarSaida(int id, double quantidade, String? observacoes) async {
    try {
      final m = await _repo.registrarSaida(id, quantidade, observacoes);
      final idx = _materiais.indexWhere((x) => x.id == id);
      if (idx != -1) _materiais[idx] = m;
      notifyListeners();
      return m;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  Future<void> carregarHistoricoGeral() async {
    _setLoading(true);
    try {
      _historico = await _repo.historicoGeral();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<List<HistoricoEstoque>> buscarHistoricoMaterial(int id) async {
    return _repo.buscarHistorico(id);
  }

  Future<bool> desativar(int id) async {
    try {
      final m = await _repo.atualizar(id, {'status': 'INATIVO'});
      final idx = _materiais.indexWhere((x) => x.id == id);
      if (idx != -1) _materiais[idx] = m;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> reativar(int id) async {
    try {
      final m = await _repo.atualizar(id, {'reativar': true});
      final idx = _materiais.indexWhere((x) => x.id == id);
      if (idx != -1) _materiais[idx] = m;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  void clearError() { _error = null; notifyListeners(); }
}