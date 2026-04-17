import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/material_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/material_model.dart';

class SaidaMaterialDialog extends StatefulWidget {
  final MaterialModel material;
  const SaidaMaterialDialog({super.key, required this.material});
  @override
  State<SaidaMaterialDialog> createState() => _SaidaMaterialDialogState();
}

class _SaidaMaterialDialogState extends State<SaidaMaterialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantidade = TextEditingController();
  final _observacoes = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _quantidade.dispose(); _observacoes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final qtd = double.tryParse(_quantidade.text) ?? 0;
    if (qtd <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantidade deve ser maior que zero')),
      );
      return;
    }
    setState(() => _loading = true);
    final prov = context.read<MaterialProvider>();
    final result = await prov.registrarSaida(widget.material.id, qtd, _observacoes.text.trim().isEmpty ? null : _observacoes.text.trim());
    setState(() => _loading = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result != null ? 'Saída registrada!' : prov.error ?? 'Erro')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.material;
    return Dialog(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppTheme.statusBaixo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.output_rounded, color: AppTheme.statusBaixo, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Saída de Material', style: GoogleFonts.raleway(fontSize: 17, fontWeight: FontWeight.w700))),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.nome, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 4),
                Text('Quantidade atual: ${AppUtils.formatNumber(m.quantidadeAtual)}',
                    style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
                Text('Estoque mínimo: ${AppUtils.formatNumber(m.estoqueMinimo)}',
                    style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
              ]),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Quantidade de Saída',
              controller: _quantidade,
              keyboardType: TextInputType.number,
              required: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo obrigatório';
                final qtd = double.tryParse(v);
                if (qtd == null || qtd <= 0) return 'Informe uma quantidade válida';
                if (qtd > m.quantidadeAtual) return 'Quantidade maior que o estoque atual (${AppUtils.formatNumber(m.quantidadeAtual)})';
                return null;
              },
            ),
            const SizedBox(height: 14),
            AppTextField(label: 'Observações', controller: _observacoes, maxLines: 2),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusBaixo),
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirmar Saída'),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}