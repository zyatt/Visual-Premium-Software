import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/material_provider.dart';
import '../../widgets/common/common_widgets.dart';
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
    _nome.dispose(); _qtdAtual.dispose(); _estoqueInicial.dispose();
    _estoqueMinimo.dispose(); _custo.dispose(); _ultimoValorPago.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? (_isEdit ? 'Material atualizado!' : 'Material criado!') : prov.error ?? 'Erro')),
      );
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
              AppTextField(label: 'Nome do Material', controller: _nome, required: true),
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
                    onPressed: _loading ? null : _submit,
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