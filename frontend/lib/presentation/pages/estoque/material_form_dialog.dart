import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/material_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/material_model.dart';

class MaterialFormDialog extends StatefulWidget {
  final MaterialModel? material;
  const MaterialFormDialog({super.key, this.material});
  @override
  State<MaterialFormDialog> createState() => _MaterialFormDialogState();
}

class _MaterialFormDialogState extends State<MaterialFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
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
    _nome.dispose(); _qtdAtual.dispose(); _estoqueInicial.dispose();
    _estoqueMinimo.dispose(); _custo.dispose(); _ultimoValorPago.dispose();
    super.dispose();
  }

  void _onNomeChanged(String value) {
    // Limpa erro ao digitar
    if (_nomeError != null) setState(() => _nomeError = null);

    _debounce?.cancel();
    final trimmed = value.trim();

    if (trimmed.isEmpty) return;
    // Na edição, não verifica se o nome não mudou
    if (_isEdit && trimmed.toLowerCase() == widget.material!.nome.toLowerCase()) return;

    // Debounce de 600ms após parar de digitar
    _debounce = Timer(const Duration(milliseconds: 600), () => _verificarNome(trimmed));
  }

  Future<void> _verificarNome(String nome) async {
    setState(() => _checkingNome = true);
    final prov = context.read<MaterialProvider>();

    // Verificação local na lista já carregada no provider — sem chamada extra à API
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

  Future<void> _submit() async {
    if (_nomeError != null) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final dados = {
      'nome': _nome.text.trim(),
      'quantidadeAtual': double.tryParse(_qtdAtual.text) ?? 0,
      'estoqueInicial': double.tryParse(_estoqueInicial.text) ?? 0,
      'estoqueMinimo': double.tryParse(_estoqueMinimo.text) ?? 0,
      'custo': double.tryParse(_custo.text) ?? 0,
      'ultimoValorPago': double.tryParse(_ultimoValorPago.text) ?? 0,
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
        // Caso o backend rejeite (ex: race condition), exibe o erro no próprio campo
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
              Row(children: [
                Expanded(child: AppTextField(
                  label: 'Quantidade Atual', controller: _qtdAtual,
                  keyboardType: TextInputType.number,
                )),
                const SizedBox(width: 12),
                Expanded(child: AppTextField(
                  label: 'Estoque Inicial', controller: _estoqueInicial,
                  keyboardType: TextInputType.number,
                )),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: AppTextField(
                  label: 'Estoque Mínimo', controller: _estoqueMinimo,
                  keyboardType: TextInputType.number,
                )),
                const SizedBox(width: 12),
                Expanded(child: AppTextField(
                  label: 'Custo (R\$)', controller: _custo,
                  keyboardType: TextInputType.number,
                )),
              ]),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Último Valor Pago (R\$)', controller: _ultimoValorPago,
                keyboardType: TextInputType.number,
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