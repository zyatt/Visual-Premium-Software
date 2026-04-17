import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/fornecedor_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../../data/models/fornecedor_model.dart';

class FornecedorFormDialog extends StatefulWidget {
  final Fornecedor? fornecedor;
  const FornecedorFormDialog({super.key, this.fornecedor});
  @override
  State<FornecedorFormDialog> createState() => _FornecedorFormDialogState();
}

class _FornecedorFormDialogState extends State<FornecedorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _tipo = TextEditingController();
  final _telefone = TextEditingController();
  final _razaoSocial = TextEditingController();
  final _nomeFantasia = TextEditingController();
  final _cnpj = TextEditingController();
  bool _loading = false;

  bool get _isEdit => widget.fornecedor != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final f = widget.fornecedor!;
      _nome.text = f.nome;
      _tipo.text = f.tipoFornecedor ?? '';
      _telefone.text = f.telefone ?? '';
      _razaoSocial.text = f.razaoSocial ?? '';
      _nomeFantasia.text = f.nomeFantasia ?? '';
      _cnpj.text = f.cnpj ?? '';
    }
  }

  @override
  void dispose() {
    _nome.dispose(); _tipo.dispose(); _telefone.dispose();
    _razaoSocial.dispose(); _nomeFantasia.dispose(); _cnpj.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final dados = {
      'nome': _nome.text.trim(),
      if (_tipo.text.trim().isNotEmpty) 'tipoFornecedor': _tipo.text.trim(),
      if (_telefone.text.trim().isNotEmpty) 'telefone': _telefone.text.trim(),
      if (_razaoSocial.text.trim().isNotEmpty) 'razaoSocial': _razaoSocial.text.trim(),
      if (_nomeFantasia.text.trim().isNotEmpty) 'nomeFantasia': _nomeFantasia.text.trim(),
      if (_cnpj.text.trim().isNotEmpty) 'cnpj': _cnpj.text.trim(),
    };

    final prov = context.read<FornecedorProvider>();
    final ok = _isEdit
        ? await prov.atualizar(widget.fornecedor!.id, dados) != null
        : await prov.criar(dados) != null;

    setState(() => _loading = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? (_isEdit ? 'Fornecedor atualizado!' : 'Fornecedor criado!') : prov.error ?? 'Erro')),
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
              Row(children: [
                Text(_isEdit ? 'Editar Fornecedor' : 'Novo Fornecedor',
                    style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 20),
              AppTextField(label: 'Nome do Fornecedor', controller: _nome, required: true),
              const SizedBox(height: 14),
              AppTextField(label: 'Tipo de Fornecedor', controller: _tipo),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: AppTextField(label: 'Telefone', controller: _telefone)),
                const SizedBox(width: 12),
                Expanded(child: AppTextField(label: 'CNPJ', controller: _cnpj)),
              ]),
              const SizedBox(height: 14),
              AppTextField(label: 'Razão Social', controller: _razaoSocial),
              const SizedBox(height: 14),
              AppTextField(label: 'Nome Fantasia', controller: _nomeFantasia),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isEdit ? 'Atualizar' : 'Cadastrar'),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}