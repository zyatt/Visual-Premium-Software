import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/fornecedor_provider.dart';
import '../../providers/material_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/fornecedor_model.dart';
import '../../../data/models/material_model.dart';

class VincularMaterialDialog extends StatefulWidget {
  final Fornecedor fornecedor;
  const VincularMaterialDialog({super.key, required this.fornecedor});
  @override
  State<VincularMaterialDialog> createState() => _VincularMaterialDialogState();
}

class _VincularMaterialDialogState extends State<VincularMaterialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _custo = TextEditingController();
  final _prazo = TextEditingController();
  MaterialModel? _materialSelecionado;
  bool _loading = false;

  @override
  void dispose() { _custo.dispose(); _prazo.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _materialSelecionado == null) return;
    setState(() => _loading = true);
    final prov = context.read<FornecedorProvider>();
    final ok = await prov.adicionarMaterial(
      widget.fornecedor.id,
      _materialSelecionado!.id,
      double.tryParse(_custo.text) ?? 0,
      int.tryParse(_prazo.text),
    );
    setState(() => _loading = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Material vinculado!' : prov.error ?? 'Erro')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final materiais = context.watch<MaterialProvider>().materiaisAtivos; // <-- ALTERADO
    final jaVinculados = widget.fornecedor.materiais.map((m) => m.materialId).toSet();
    final disponiveis = materiais
        .whereType<MaterialModel>()
        .where((m) => !jaVinculados.contains(m.id))
        .toList();

    return Dialog(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Vincular Material', style: GoogleFonts.raleway(fontSize: 17, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            ]),
            Text('Fornecedor: ${widget.fornecedor.nome}',
                style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            DropdownButtonFormField<MaterialModel>(
              initialValue: _materialSelecionado,
              decoration: const InputDecoration(labelText: 'Selecionar Material *'),
              items: disponiveis
                  .map<DropdownMenuItem<MaterialModel>>(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(m.nome),
                    ),
                  )
                  .toList(),
              onChanged: (MaterialModel? v) {
                setState(() => _materialSelecionado = v);
              },
              validator: (v) => v == null ? 'Selecione um material' : null,
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: AppTextField(
                label: 'Custo (R\$)', controller: _custo,
                keyboardType: TextInputType.number, required: true,
              )),
              const SizedBox(width: 12),
              Expanded(child: AppTextField(
                label: 'Prazo de Entrega (dias)', controller: _prazo,
                keyboardType: TextInputType.number,
              )),
            ]),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Vincular'),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}