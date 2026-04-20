import 'package:flutter/foundation.dart';
import '../../data/models/ordem_compra_model.dart';
import '../../data/models/historico_compra_model.dart';
import '../../data/repositories/ordem_compra_repository.dart';

class OrdemCompraProvider extends ChangeNotifier {
  final _repo = OrdemCompraRepository();

  List<OrdemCompra> _ordens = [];
  bool _loading = false;
  String? _error;

  List<HistoricoCompraEntry> _historico = [];
  bool _loadingHistorico = false;

  List<OrdemCompra> get ordens => _ordens;
  bool get loading => _loading;
  String? get error => _error;

  List<HistoricoCompraEntry> get historico => _historico;
  bool get loadingHistorico => _loadingHistorico;

  List<OrdemCompra> get ordensEmAndamento =>
      _ordens.where((o) => o.status == 'EM_ANDAMENTO').toList();
  List<OrdemCompra> get ordensFinalizadas =>
      _ordens.where((o) => o.status == 'FINALIZADO').toList();
  List<OrdemCompra> get ordensCanceladas =>
      _ordens.where((o) => o.status == 'CANCELADO').toList();

  void _setLoading(bool v) { _loading = v; notifyListeners(); }
  void _setError(String? v) { _error = v; notifyListeners(); }

  Future<int?> buscarProximoNumero() async {
    try {
      return await _repo.buscarProximoNumero();
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  Future<void> carregarOrdens() async {
    _setLoading(true);
    _setError(null);
    try {
      _ordens = await _repo.listarTodos();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<OrdemCompra?> buscarPorId(int id) async {
    try {
      return await _repo.buscarPorId(id);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  Future<OrdemCompra?> criar(Map<String, dynamic> dados) async {
    try {
      final o = await _repo.criar(dados);
      _ordens.insert(0, o);
      notifyListeners();
      return o;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  Future<OrdemCompra?> atualizar(int id, Map<String, dynamic> dados) async {
    try {
      final o = await _repo.atualizar(id, dados);
      final idx = _ordens.indexWhere((x) => x.id == id);
      if (idx != -1) _ordens[idx] = o;
      notifyListeners();
      return o;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  Future<OrdemCompra?> cancelar(int id) async {
    try {
      final o = await _repo.cancelar(id);
      final idx = _ordens.indexWhere((x) => x.id == id);
      if (idx != -1) _ordens[idx] = o;
      notifyListeners();
      return o;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  Future<OrdemCompra?> finalizar(int id) async {
    try {
      final o = await _repo.finalizar(id);
      final idx = _ordens.indexWhere((x) => x.id == id);
      if (idx != -1) _ordens[idx] = o;
      notifyListeners();
      return o;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  Future<OrdemCompraItem?> adicionarItem(int ordemId, Map<String, dynamic> item) async {
    try {
      final i = await _repo.adicionarItem(ordemId, item);
      await carregarOrdens();
      return i;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  Future<bool> removerItem(int ordemId, int itemId) async {
    try {
      await _repo.removerItem(ordemId, itemId);
      await carregarOrdens();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<void> carregarHistorico({
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    _loadingHistorico = true;
    _error = null;
    notifyListeners();
    try {
      _historico = await _repo.listarHistorico(
        dataInicio: dataInicio,
        dataFim: dataFim,
      );
    } catch (e) {
      _setError(e.toString());
    } finally {
      _loadingHistorico = false;
      notifyListeners();
    }
  }

  void clearError() { _error = null; notifyListeners(); }
}