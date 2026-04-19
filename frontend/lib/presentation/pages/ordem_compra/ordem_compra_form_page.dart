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
import '../../../data/models/ordem_compra_model.dart';

class _ItemOC {
  MaterialModel? material;
  Fornecedor? fornecedor;
  final quantidade = TextEditingController();
  final precoUnitario = TextEditingController();
  final prazoEntrega = TextEditingController();
  final observacoes = TextEditingController();

  _ItemOC({this.material, this.fornecedor, String? qtd, String? preco, String? prazo, String? obs}) {
    if (qtd != null) quantidade.text = qtd;
    if (preco != null) precoUnitario.text = preco;
    if (prazo != null) prazoEntrega.text = prazo;
    if (obs != null) observacoes.text = obs;
  }

  double get precoTotal =>
      (double.tryParse(quantidade.text) ?? 0) * (double.tryParse(precoUnitario.text) ?? 0);

  void dispose() {
    quantidade.dispose();
    precoUnitario.dispose();
    prazoEntrega.dispose();
    observacoes.dispose();
  }
}

class OrdemCompraFormPage extends StatefulWidget {
  /// Se fornecido, a página entra em modo de edição
  final OrdemCompra? ordemParaEditar;
  /// Se true + ordemParaEditar != null, trata como nova OC pré-preenchida (vindo do comparativo)
  final bool modoNovo;

  const OrdemCompraFormPage({super.key, this.ordemParaEditar, this.modoNovo = false});

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
  final List<_ItemOC> _itens = [];
  bool _loading = false;

  bool get _isEditing => widget.ordemParaEditar != null && !widget.modoNovo;

  @override
  void initState() {
    super.initState();
    if (!_isEditing) {
      _itens.add(_ItemOC());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarEPreencher();
    });
  }

  Future<void> _carregarEPreencher() async {
    await Future.wait([
      context.read<FornecedorProvider>().carregarFornecedores(),
      context.read<MaterialProvider>().carregarMateriais(),
    ]);
    if (mounted && _isEditing) _preencherParaEdicao();
  }

  void _preencherParaEdicao() {
    final oc = widget.ordemParaEditar!;
    if (oc.numeroOC.isNotEmpty) _numeroOC.text = oc.numeroOC;
    _formaPagamento.text = oc.formaPagamento ?? '';
    _observacoes.text = oc.observacoes ?? '';
    _data = oc.data;

    final fornecedores = context.read<FornecedorProvider>().fornecedores;
    final materiais = context.read<MaterialProvider>().materiais;

    setState(() {
      _fornecedor = oc.fornecedorId != null
          ? fornecedores.where((f) => f.id == oc.fornecedorId).firstOrNull ??
            oc.fornecedor
          : null;

      _itens.clear();
      for (final item in oc.itens) {
        final mat = materiais.where((m) => m.id == item.materialId).firstOrNull
            ?? item.material;

        Fornecedor? forn;
        if (item.fornecedorId != null) {
          forn = fornecedores.where((f) => f.id == item.fornecedorId).firstOrNull
              ?? item.fornecedor;
        }

        _itens.add(_ItemOC(
          material: mat,
          fornecedor: forn,
          qtd: item.quantidade == 1 && widget.modoNovo ? '' : item.quantidade.toString(),
          preco: item.precoUnitario.toString(),
          prazo: item.prazoEntrega?.toString(),
          obs: item.observacoes,
        ));
      }
      if (_itens.isEmpty) _itens.add(_ItemOC());
    });
  }

  @override
  void dispose() {
    _numeroOC.dispose();
    _formaPagamento.dispose();
    _observacoes.dispose();
    for (final i in _itens) {
      i.dispose();
    }
    super.dispose();
  }

  double get _totalGeral => _itens.fold(0, (s, i) => s + i.precoTotal);

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (d != null) setState(() => _data = d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_numeroOC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Informe o número da OC')));
      return;
    }

    setState(() => _loading = true);

    final dados = {
      'numeroOC': _numeroOC.text.trim(),
      'data': _data.toIso8601String(),
      if (_formaPagamento.text.trim().isNotEmpty) 'formaPagamento': _formaPagamento.text.trim(),
      if (_fornecedor != null) 'fornecedorId': _fornecedor!.id,
      if (_observacoes.text.trim().isNotEmpty) 'observacoes': _observacoes.text.trim(),
      'itens': _itens
          .where((i) => i.material != null)
          .map((i) => {
                'materialId': i.material!.id,
                if (i.fornecedor != null) 'fornecedorId': i.fornecedor!.id,
                'quantidade': double.tryParse(i.quantidade.text) ?? 0,
                'precoUnitario': double.tryParse(i.precoUnitario.text) ?? 0,
                'precoTotal': i.precoTotal,
                if (i.prazoEntrega.text.isNotEmpty)
                  'prazoEntrega': int.tryParse(i.prazoEntrega.text),
                if (i.observacoes.text.isNotEmpty) 'observacoes': i.observacoes.text,
              })
          .toList(),
    };

    final prov = context.read<OrdemCompraProvider>();
    OrdemCompra? result;

    if (_isEditing) {
      result = await prov.atualizar(widget.ordemParaEditar!.id, dados);
    } else {
      result = await prov.criar(dados);
    }

    setState(() => _loading = false);

    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'OC atualizada!' : 'Ordem de Compra criada!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(prov.error ?? 'Erro ao salvar OC')),
        );
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
        title: Text(_isEditing ? 'Editar Ordem de Compra' : 'Nova Ordem de Compra'),        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEditing ? 'Salvar Alterações' : 'Salvar OC'),
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
                  Expanded(
                    child: AppTextField(
                        label: 'Número OC *', controller: _numeroOC, required: true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Data',
                      controller: TextEditingController(text: AppUtils.formatDate(_data)),
                      readOnly: true,
                      onTap: _pickDate,
                      suffix: const Icon(Icons.calendar_today_rounded, size: 16),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: AppTextField(
                        label: 'Forma de Pagamento (opcional)',
                        controller: _formaPagamento),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<Fornecedor?>(
                      initialValue: fornecedores.where((f) => f.id == _fornecedor?.id).firstOrNull,
                      decoration:
                          const InputDecoration(labelText: 'Fornecedor (opcional)'),
                      items: [
                        const DropdownMenuItem<Fornecedor?>(
                            value: null, child: Text('— Nenhum —')),
                        ...fornecedores.map(
                            (f) => DropdownMenuItem(value: f, child: Text(f.nome))),
                      ],
                      onChanged: (v) => setState(() => _fornecedor = v),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                AppTextField(
                    label: 'Observações', controller: _observacoes, maxLines: 2),
              ]),
            ),
            const SizedBox(height: 20),

            // Itens
            _SectionCard(
              title: 'Itens da OC (opcional)',
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
                                style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppTheme.primary)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_rounded,
                                  size: 16, color: AppTheme.error),
                              onPressed: () => setState(() {
                                item.dispose();
                                _itens.removeAt(idx);
                              }),
                            ),
                          ]),
                          const SizedBox(height: 8),

                          // Material
                          DropdownButtonFormField<MaterialModel?>(
                            initialValue: materiais.where((m) => m.id == item.material?.id).firstOrNull,
                            decoration: const InputDecoration(
                                labelText: 'Material',
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white),
                            items: [
                              const DropdownMenuItem<MaterialModel?>(
                                  value: null, child: Text('— Selecione —')),
                              ...materiais.map((m) =>
                                  DropdownMenuItem(value: m, child: Text(m.nome))),
                            ],
                            onChanged: (v) => setState(() => item.material = v),
                          ),
                          const SizedBox(height: 10),

                          // Fornecedor por item
                          DropdownButtonFormField<Fornecedor?>(
                            initialValue: fornecedores.where((f) => f.id == item.fornecedor?.id).firstOrNull,
                            decoration: const InputDecoration(
                                labelText: 'Fornecedor do item (opcional)',
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white),
                            items: [
                              const DropdownMenuItem<Fornecedor?>(
                                  value: null, child: Text('— Nenhum —')),
                              ...fornecedores.map((f) =>
                                  DropdownMenuItem(value: f, child: Text(f.nome))),
                            ],
                            onChanged: (v) => setState(() => item.fornecedor = v),
                          ),
                          const SizedBox(height: 10),

                          Row(children: [
                            Expanded(
                              child: TextFormField(
                                controller: item.quantidade,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: 'Quantidade',
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: item.precoUnitario,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: 'Preço Unitário',
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.divider)),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Preço Total',
                                          style: GoogleFonts.nunito(
                                              fontSize: 10, color: AppTheme.textHint)),
                                      Text(AppUtils.formatCurrency(item.precoTotal),
                                          style: GoogleFonts.nunito(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: AppTheme.primary)),
                                    ]),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(
                              child: TextFormField(
                                controller: item.prazoEntrega,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: 'Prazo (dias)',
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: item.observacoes,
                                decoration: const InputDecoration(
                                    labelText: 'Observações do item',
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white),
                              ),
                            ),
                          ]),
                        ]),
                      );
                    });
                  }),
                  if (_itens.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'Nenhum item adicionado. Você pode salvar a OC sem itens.',
                          style: GoogleFonts.nunito(
                              fontSize: 12, color: AppTheme.textHint),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  // Total
                  if (_itens.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        Text('Total Geral:',
                            style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(width: 12),
                        Text(AppUtils.formatCurrency(_totalGeral),
                            style: GoogleFonts.raleway(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: AppTheme.primary)),
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title,
              style: GoogleFonts.raleway(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          if (trailing != null) ...[const Spacer(), trailing!],
        ]),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}