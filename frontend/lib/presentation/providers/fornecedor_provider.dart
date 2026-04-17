import 'package:flutter/foundation.dart';
import '../../data/models/fornecedor_model.dart';
import '../../data/repositories/fornecedor_repository.dart';

class FornecedorProvider extends ChangeNotifier {
  final _repo = FornecedorRepository();

  List<Fornecedor> _fornecedores = [];
  bool _loading = false;
  String? _error;

  List<Fornecedor> get fornecedores => _fornecedores;
  bool get loading => _loading;
  String? get error => _error;

  void _setLoading(bool v) { _loading = v; notifyListeners(); }
  void _setError(String? v) { _error = v; notifyListeners(); }

  Future<void> carregarFornecedores() async {
    _setLoading(true);
    _setError(null);
    try {
      _fornecedores = await _repo.listarTodos();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<Fornecedor?> criar(Map<String, dynamic> dados) async {
    try {
      final f = await _repo.criar(dados);
      _fornecedores.add(f);
      notifyListeners();
      return f;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  Future<Fornecedor?> atualizar(int id, Map<String, dynamic> dados) async {
    try {
      final f = await _repo.atualizar(id, dados);
      final idx = _fornecedores.indexWhere((x) => x.id == id);
      if (idx != -1) _fornecedores[idx] = f;
      notifyListeners();
      return f;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  Future<bool> deletar(int id) async {
    try {
      await _repo.deletar(id);
      _fornecedores.removeWhere((f) => f.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> adicionarMaterial(int fornecedorId, int materialId, double custo, int? prazoEntrega) async {
    try {
      await _repo.adicionarMaterial(fornecedorId, materialId, custo, prazoEntrega);
      await carregarFornecedores();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> removerMaterial(int fornecedorId, int materialId) async {
    try {
      await _repo.removerMaterial(fornecedorId, materialId);
      await carregarFornecedores();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  void clearError() { _error = null; notifyListeners(); }
}