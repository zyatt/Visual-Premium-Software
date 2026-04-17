import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/ordem_compra_provider.dart';
import '../../providers/fornecedor_provider.dart';
import '../../providers/material_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/material_model.dart';
import '../../../data/models/fornecedor_model.dart';

class _ItemOC {
  MaterialModel? material;
  final quantidade = TextEditingController();
  final precoUnitario = TextEditingController();
  final prazoEntrega = TextEditingController();
  final observacoes = TextEditingController();

  double get precoTotal =>
      (double.tryParse(quantidade.text) ?? 0) * (double.tryParse(precoUnitario.text) ?? 0);

  void dispose() {
    quantidade.dispose(); precoUnitario.dispose();
    prazoEntrega.dispose(); observacoes.dispose();
  }
}

class OrdemCompraFormPage extends StatefulWidget {
  const OrdemCompraFormPage({super.key});
  @override
  State<OrdemCompraFormPage> createState() => _OrdemCompraFormPageState();
}

class _OrdemCompraFormPageState extends State<OrdemCompraFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _numeroOC = TextEditingController();
  final _formaPagamento = TextEditingController();
  final _observacoes = TextEditingController();
  DateTime _data = DateTime.now();
  Fornecedor? _fornecedor;
  final List<_ItemOC> _itens = [_ItemOC()];
  bool _loading = false;

  @override
  void dispose() {
    _numeroOC.dispose(); _formaPagamento.dispose(); _observacoes.dispose();
    for (final i in _itens) {
      i.dispose();
    }
    super.dispose();
  }

  double get _totalGeral => _itens.fold(0, (s, i) => s + i.precoTotal);

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context, initialDate: _data,
      firstDate: DateTime(2020), lastDate: DateTime(2030),
    );
    if (d != null) setState(() => _data = d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fornecedor == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um fornecedor')));
      return;
    }
    if (_itens.any((i) => i.material == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione o material de todos os itens')));
      return;
    }
    setState(() => _loading = true);

    final dados = {
      'numeroOC': _numeroOC.text.trim(),
      'data': _data.toIso8601String(),
      'formaPagamento': _formaPagamento.text.trim(),
      'fornecedorId': _fornecedor!.id,
      if (_observacoes.text.trim().isNotEmpty) 'observacoes': _observacoes.text.trim(),
      'itens': _itens.map((i) => {
        'materialId': i.material!.id,
        'quantidade': double.tryParse(i.quantidade.text) ?? 0,
        'precoUnitario': double.tryParse(i.precoUnitario.text) ?? 0,
        'precoTotal': i.precoTotal,
        if (i.prazoEntrega.text.isNotEmpty) 'prazoEntrega': int.tryParse(i.prazoEntrega.text),
        if (i.observacoes.text.isNotEmpty) 'observacoes': i.observacoes.text,
      }).toList(),
    };

    final prov = context.read<OrdemCompraProvider>();
    final result = await prov.criar(dados);
    setState(() => _loading = false);
    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ordem de Compra criada!')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(prov.error ?? 'Erro ao criar OC')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fornecedores = context.watch<FornecedorProvider>().fornecedores;
    final materiais = context.watch<MaterialProvider>().materiais;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Nova Ordem de Compra'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Salvar OC'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Dados principais
            _SectionCard(
              title: 'Dados da OC',
              child: Column(children: [
                Row(children: [
                  Expanded(child: AppTextField(label: 'Número OC', controller: _numeroOC, required: true)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Data', controller: TextEditingController(text: AppUtils.formatDate(_data)),
                      readOnly: true, onTap: _pickDate,
                      suffix: const Icon(Icons.calendar_today_rounded, size: 16),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: AppTextField(label: 'Forma de Pagamento', controller: _formaPagamento, required: true)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<Fornecedor>(
                      initialValue: _fornecedor,
                      decoration: const InputDecoration(labelText: 'Fornecedor *'),
                      items: fornecedores.map((f) => DropdownMenuItem(value: f, child: Text(f.nome))).toList(),
                      onChanged: (v) => setState(() => _fornecedor = v),
                      validator: (v) => v == null ? 'Selecione um fornecedor' : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                AppTextField(label: 'Observações', controller: _observacoes, maxLines: 2),
              ]),
            ),
            const SizedBox(height: 20),
            // Itens
            _SectionCard(
              title: 'Itens da OC',
              trailing: TextButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Adicionar Item'),
                onPressed: () => setState(() => _itens.add(_ItemOC())),
              ),
              child: Column(
                children: [
                  ..._itens.asMap().entries.map((e) {
                    final idx = e.key;
                    final item = e.value;
                    return StatefulBuilder(builder: (ctx, setS) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text('Item ${idx + 1}',
                                style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.primary)),
                            const Spacer(),
                            if (_itens.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_rounded, size: 16, color: AppTheme.error),
                                onPressed: () => setState(() { item.dispose(); _itens.removeAt(idx); }),
                              ),
                          ]),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<MaterialModel>(
                            initialValue: item.material,
                            decoration: const InputDecoration(labelText: 'Material *', isDense: true, filled: true, fillColor: Colors.white),
                            items: materiais.map((m) => DropdownMenuItem(value: m, child: Text(m.nome))).toList(),
                            onChanged: (v) => setState(() => item.material = v),
                          ),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(child: TextFormField(
                              controller: item.quantidade,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Quantidade', isDense: true, filled: true, fillColor: Colors.white),
                              onChanged: (_) => setState(() {}),
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: TextFormField(
                              controller: item.precoUnitario,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Preço Unitário', isDense: true, filled: true, fillColor: Colors.white),
                              onChanged: (_) => setState(() {}),
                            )),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.divider)),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('Preço Total', style: GoogleFonts.nunito(fontSize: 10, color: AppTheme.textHint)),
                                  Text(AppUtils.formatCurrency(item.precoTotal),
                                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.primary)),
                                ]),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(child: TextFormField(
                              controller: item.prazoEntrega,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Prazo (dias)', isDense: true, filled: true, fillColor: Colors.white),
                            )),
                            const SizedBox(width: 10),
                            Expanded(flex: 2, child: TextFormField(
                              controller: item.observacoes,
                              decoration: const InputDecoration(labelText: 'Observações do item', isDense: true, filled: true, fillColor: Colors.white),
                            )),
                          ]),
                        ]),
                      );
                    });
                  }),
                  // Total
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text('Total Geral:', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(width: 12),
                      Text(AppUtils.formatCurrency(_totalGeral),
                          style: GoogleFonts.raleway(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.primary)),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title, style: GoogleFonts.raleway(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          if (trailing != null) ...[const Spacer(), trailing!],
        ]),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}