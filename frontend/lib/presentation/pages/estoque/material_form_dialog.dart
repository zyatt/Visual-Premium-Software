import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/material_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/material_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helper: aceita vírgula OU ponto como separador decimal.
// "1"      → 1.0
// "1,5"    → 1.5
// "1.500,75" → 1500.75  (formato BR com milhar)
// "1,500.75" → 1500.75  (formato EN com milhar)
// ─────────────────────────────────────────────────────────────────────────────
double _parseDecimal(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return 0.0;

  // Caso simples: já é um double válido (ex: "1", "1.5")
  final direct = double.tryParse(s);
  if (direct != null) return direct;

  // Detecta formato: se há ponto E vírgula, o último é o separador decimal
  final hasDot   = s.contains('.');
  final hasComma = s.contains(',');

  String normalized;

  if (hasDot && hasComma) {
    // Ex: "1.500,75" (BR) ou "1,500.75" (EN)
    final lastDot   = s.lastIndexOf('.');
    final lastComma = s.lastIndexOf(',');
    if (lastComma > lastDot) {
      // BR: vírgula é o decimal → remove pontos de milhar, troca vírgula por ponto
      normalized = s.replaceAll('.', '').replaceAll(',', '.');
    } else {
      // EN: ponto é o decimal → remove vírgulas de milhar
      normalized = s.replaceAll(',', '');
    }
  } else if (hasComma) {
    // Só vírgula: pode ser separador decimal (BR) ou milhar (EN raro)
    final parts = s.split(',');
    if (parts.length == 2 && parts[1].length <= 2) {
      // "1,5" ou "1,75" → decimal
      normalized = s.replaceAll(',', '.');
    } else {
      // "1,500" → milhar, remove vírgula
      normalized = s.replaceAll(',', '');
    }
  } else {
    // Só ponto com parse falhou (ex: "1.500" como milhar BR)
    normalized = s.replaceAll('.', '');
  }

  return double.tryParse(normalized) ?? 0.0;
}

class MaterialFormDialog extends StatefulWidget {
  final MaterialModel? material;
  const MaterialFormDialog({super.key, this.material});
  @override
  State<MaterialFormDialog> createState() => _MaterialFormDialogState();
}

class _MaterialFormDialogState extends State<MaterialFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _unidade = TextEditingController();
  final _qtdAtual = TextEditingController();
  final _estoqueInicial = TextEditingController();
  final _estoqueMinimo = TextEditingController();
  final _custo = TextEditingController();
  final _ultimoValorPago = TextEditingController();
  bool _loading = false;

  // Validação de nome duplicado
  String? _nomeError;
  bool _checkingNome = false;
  Timer? _debounce;

  bool get _isEdit => widget.material != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final m = widget.material!;
      _nome.text = m.nome;
      _unidade.text = m.unidade ?? '';
      _qtdAtual.text = m.quantidadeAtual.toString();
      _estoqueInicial.text = m.estoqueInicial.toString();
      _estoqueMinimo.text = m.estoqueMinimo.toString();
      _custo.text = m.custo.toString();
      _ultimoValorPago.text = m.ultimoValorPago.toString();
    } else {
      _qtdAtual.text = '0';
      _estoqueInicial.text = '0';
      _estoqueMinimo.text = '0';
      _custo.text = '0';
      _ultimoValorPago.text = '0';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nome.dispose(); _unidade.dispose(); _qtdAtual.dispose(); _estoqueInicial.dispose();
    _estoqueMinimo.dispose(); _custo.dispose(); _ultimoValorPago.dispose();
    super.dispose();
  }

  void _onNomeChanged(String value) {
    if (_nomeError != null) setState(() => _nomeError = null);

    _debounce?.cancel();
    final trimmed = value.trim();

    if (trimmed.isEmpty) return;
    if (_isEdit && trimmed.toLowerCase() == widget.material!.nome.toLowerCase()) return;

    _debounce = Timer(const Duration(milliseconds: 600), () => _verificarNome(trimmed));
  }

  Future<void> _verificarNome(String nome) async {
    setState(() => _checkingNome = true);
    final prov = context.read<MaterialProvider>();

    final existe = prov.materiais.any((m) =>
        m.nome.toLowerCase() == nome.toLowerCase() &&
        (!_isEdit || m.id != widget.material!.id));

    if (mounted) {
      setState(() {
        _checkingNome = false;
        _nomeError = existe ? 'Já existe um material com este nome' : null;
      });
      _formKey.currentState?.validate();
    }
  }

  /// Validator reutilizável para campos numéricos: permite vazio (vira 0)
  /// mas rejeita texto que não seja número.
  String? _validarNumero(String? v) {
    if (v == null || v.trim().isEmpty) return null; // vazio → 0, tudo bem
    final parsed = _parseDecimal(v.trim());
    // Se parseDecimal retornou 0 mas o campo não era "0" ou vazio, é inválido
    if (parsed == 0.0 && v.trim() != '0' && v.trim() != '0,0' && v.trim() != '0.0') {
      // Checa se realmente não é zero digitado
      final semZeros = v.trim().replaceAll(RegExp(r'[0.,]'), '');
      if (semZeros.isNotEmpty) return 'Valor inválido';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_nomeError != null) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final dados = {
      'nome': _nome.text.trim(),
      'unidade': _unidade.text.trim().isEmpty ? null : _unidade.text.trim(),
      'quantidadeAtual': _parseDecimal(_qtdAtual.text),
      'estoqueInicial':  _parseDecimal(_estoqueInicial.text),
      'estoqueMinimo':   _parseDecimal(_estoqueMinimo.text),
      'custo':           _parseDecimal(_custo.text),
      'ultimoValorPago': _parseDecimal(_ultimoValorPago.text),
    };

    final prov = context.read<MaterialProvider>();
    final ok = _isEdit
        ? await prov.atualizar(widget.material!.id, dados) != null
        : await prov.criar(dados) != null;

    setState(() => _loading = false);
    if (mounted) {
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Material atualizado!' : 'Material criado!')),
        );
      } else {
        setState(() => _nomeError = prov.error ?? 'Erro ao salvar');
        _formKey.currentState?.validate();
        prov.clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  Text(
                    _isEdit ? 'Editar Material' : 'Novo Material',
                    style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),

              // Campo nome com validação em tempo real
              TextFormField(
                controller: _nome,
                onChanged: _onNomeChanged,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
                  if (_nomeError != null) return _nomeError;
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Nome do Material *',
                  suffixIcon: _checkingNome
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primary,
                            ),
                          ),
                        )
                      : _nomeError != null
                          ? const Icon(Icons.error_rounded, color: AppTheme.error, size: 20)
                          : _nome.text.trim().isNotEmpty
                              ? const Icon(Icons.check_circle_rounded, color: AppTheme.statusOk, size: 20)
                              : null,
                ),
              ),

              const SizedBox(height: 14),

              // Campo unidade
              AppTextField(
                label: 'Unidade (ex: kg, m², pç, L)',
                controller: _unidade,
              ),

              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: AppTextField(
                  label: 'Quantidade Atual', controller: _qtdAtual,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _validarNumero,
                )),
                const SizedBox(width: 12),
                Expanded(child: AppTextField(
                  label: 'Estoque Inicial', controller: _estoqueInicial,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _validarNumero,
                )),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: AppTextField(
                  label: 'Estoque Mínimo', controller: _estoqueMinimo,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _validarNumero,
                )),
                const SizedBox(width: 12),
                Expanded(child: AppTextField(
                  label: 'Custo (R\$)', controller: _custo,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _validarNumero,
                )),
              ]),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Último Valor Pago (R\$)', controller: _ultimoValorPago,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _validarNumero,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: (_loading || _checkingNome || _nomeError != null) ? null : _submit,
                    child: _loading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isEdit ? 'Atualizar' : 'Cadastrar'),
                  ),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }
}