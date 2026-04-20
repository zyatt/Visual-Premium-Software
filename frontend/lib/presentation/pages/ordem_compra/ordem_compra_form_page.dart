import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/ordem_compra_provider.dart';
import '../../providers/fornecedor_provider.dart';
import '../../providers/material_provider.dart';
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

  _ItemOC({
    this.material,
    String? qtd,
    String? preco,
    String? prazo,
    String? obs,
  }) {
    if (qtd != null) quantidade.text = qtd;
    if (preco != null) precoUnitario.text = preco;
    if (prazo != null) prazoEntrega.text = prazo;
    if (obs != null) observacoes.text = obs;
  }

  double get precoTotal =>
      (double.tryParse(quantidade.text) ?? 0) *
      (double.tryParse(precoUnitario.text) ?? 0);

  void dispose() {
    quantidade.dispose();
    precoUnitario.dispose();
    prazoEntrega.dispose();
    observacoes.dispose();
  }
}

class OrdemCompraFormPage extends StatefulWidget {
  final OrdemCompra? ordemParaEditar;
  final bool modoNovo;

  const OrdemCompraFormPage({
    super.key,
    this.ordemParaEditar,
    this.modoNovo = false,
  });

  @override
  State<OrdemCompraFormPage> createState() => _OrdemCompraFormPageState();
}

class _OrdemCompraFormPageState extends State<OrdemCompraFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _numeroOC = TextEditingController();
  final _formaPagamento = TextEditingController();
  final _observacoesCtrl = TextEditingController();
  DateTime _data = DateTime.now();

  int? _fornecedorId;
  final List<_ItemOC> _itens = [];
  final Map<int, int?> _itemFornecedorIds = {};

  bool _loading = false;
  bool _dadosCarregados = false;
  bool _carregandoNumero = false;

  bool get _isEditing => widget.ordemParaEditar != null && !widget.modoNovo;

  @override
  void initState() {
    super.initState();
    if (!_isEditing) _itens.add(_ItemOC());
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarEPreencher());
  }

  Future<void> _carregarEPreencher() async {
    await Future.wait([
      context.read<FornecedorProvider>().carregarFornecedores(),
      context.read<MaterialProvider>().carregarMateriais(),
    ]);
    if (!mounted) return;
    if (_isEditing) {
      _preencherParaEdicao();
    } else {
      // Busca o próximo número automático
      setState(() => _carregandoNumero = true);
      final proximo = await context.read<OrdemCompraProvider>().buscarProximoNumero();
      if (mounted) {
        setState(() {
          _carregandoNumero = false;
          if (proximo != null) _numeroOC.text = proximo.toString();
          _dadosCarregados = true;
        });
      }
    }
  }

  void _preencherParaEdicao() {
    final oc = widget.ordemParaEditar!;
    _numeroOC.text = oc.numeroOC.toString();
    _formaPagamento.text = oc.formaPagamento ?? '';
    _observacoesCtrl.text = oc.observacoes ?? '';
    _data = oc.data;

    final materiais = context.read<MaterialProvider>().materiais;

    setState(() {
      _fornecedorId = oc.fornecedorId;
      _itens.clear();
      _itemFornecedorIds.clear();

      for (var i = 0; i < oc.itens.length; i++) {
        final item = oc.itens[i];
        final mat =
            materiais.where((m) => m.id == item.materialId).firstOrNull ??
                item.material;

        _itens.add(_ItemOC(
          material: mat,
          qtd: (item.quantidade == 1 && widget.modoNovo)
              ? ''
              : item.quantidade.toString(),
          preco: item.precoUnitario.toString(),
          prazo: item.prazoEntrega?.toString(),
          obs: item.observacoes,
        ));

        if (item.fornecedorId != null) {
          _itemFornecedorIds[i] = item.fornecedorId;
        }
      }

      if (_itens.isEmpty) _itens.add(_ItemOC());
      _dadosCarregados = true;
    });
  }

  @override
  void dispose() {
    _numeroOC.dispose();
    _formaPagamento.dispose();
    _observacoesCtrl.dispose();
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
    if (_itens.any((i) => i.material != null && i.material!.status == 'INATIVO')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Remova ou substitua os materiais inativos antes de salvar.'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }

    setState(() => _loading = true);

    final itensFiltrados = _itens
        .where((i) => i.material != null)
        .toList();

    final dados = {
      'data': _data.toIso8601String(),
      if (_formaPagamento.text.trim().isNotEmpty)
        'formaPagamento': _formaPagamento.text.trim(),
      if (_fornecedorId != null) 'fornecedorId': _fornecedorId,
      if (_observacoesCtrl.text.trim().isNotEmpty)
        'observacoes': _observacoesCtrl.text.trim(),
      'itens': itensFiltrados.asMap().entries.map((e) {
        final idx = e.key;
        final i = e.value;
        return {
          'materialId': i.material!.id,
          if (_itemFornecedorIds[idx] != null)
            'fornecedorId': _itemFornecedorIds[idx],
          'quantidade': double.tryParse(i.quantidade.text) ?? 0,
          'precoUnitario': double.tryParse(i.precoUnitario.text) ?? 0,
          'precoTotal': i.precoTotal,
          if (i.prazoEntrega.text.isNotEmpty)
            'prazoEntrega': int.tryParse(i.prazoEntrega.text),
          if (i.observacoes.text.isNotEmpty) 'observacoes': i.observacoes.text,
        };
      }).toList(),
    };

    final prov = context.read<OrdemCompraProvider>();
    final result = _isEditing
        ? await prov.atualizar(widget.ordemParaEditar!.id, dados)
        : await prov.criar(dados);

    setState(() => _loading = false);

    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(_isEditing ? 'OC atualizada!' : 'Ordem de Compra criada!')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(prov.error ?? 'Erro ao salvar'),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  /// Texto do item no dropdown — sem Row, sem badge, sem widget complexo.
  /// Isso evita o crash "RenderFlex with unbounded width" dentro do DropdownMenuItem.
  String _materialLabel(MaterialModel m) {
    if (m.status == 'INATIVO') return '${m.nome} (INATIVO)';
    return m.nome;
  }

  @override
  Widget build(BuildContext context) {
    final fornecedores = context.watch<FornecedorProvider>().fornecedores;
    final todosMateriais = context.watch<MaterialProvider>().materiais;
    final materiaisAtivos =
        todosMateriais.where((m) => m.status != 'INATIVO').toList();

    final Fornecedor? fornecedorValue = _fornecedorId == null
        ? null
        : fornecedores.where((f) => f.id == _fornecedorId).firstOrNull;

    if (!_dadosCarregados) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title:
              Text(_isEditing ? 'Editar Ordem de Compra' : 'Nova Ordem de Compra'),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title:
            Text(_isEditing ? 'Editar Ordem de Compra' : 'Nova Ordem de Compra'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            ElevatedButton(
              onPressed: _submit,
              child: Text(_isEditing ? 'Salvar Alterações' : 'Criar OC'),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Dados gerais ─────────────────────────────────────────
              _SectionCard(
                title: 'Dados da Ordem de Compra',
                child: Column(children: [
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: _numeroOC,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Número da OC',
                          isDense: true,
                          filled: true,
                          fillColor: AppTheme.surfaceVariant,
                          prefixIcon: _carregandoNumero
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : const Icon(Icons.tag_rounded, size: 16),
                          suffixIcon: Tooltip(
                            message: 'Gerado automaticamente',
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Chip(
                                label: Text(
                                  'Automático',
                                  style: GoogleFonts.nunito(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary),
                                ),
                                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Data',
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            suffixIcon:
                                Icon(Icons.calendar_today_rounded, size: 16),
                          ),
                          child: Text(AppUtils.formatDate(_data),
                              style: GoogleFonts.nunito(fontSize: 13)),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<Fornecedor?>(
                    initialValue: fornecedorValue,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Fornecedor principal (opcional)',
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: [
                      const DropdownMenuItem<Fornecedor?>(
                          value: null, child: Text('— Nenhum —')),
                      ...fornecedores.map((f) => DropdownMenuItem(
                            value: f,
                            child:
                                Text(f.nome, overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (v) => setState(() => _fornecedorId = v?.id),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _formaPagamento,
                    decoration: const InputDecoration(
                      labelText: 'Forma de Pagamento (opcional)',
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _observacoesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Observações (opcional)',
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // ── Itens ─────────────────────────────────────────────────
              _SectionCard(
                title: 'Itens',
                trailing: ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Adicionar Item'),
                  onPressed: () => setState(() => _itens.add(_ItemOC())),
                ),
                child: Column(children: [
                  ...List.generate(_itens.length, (idx) {
                    final item = _itens[idx];

                    final MaterialModel? materialValue = item.material == null
                        ? null
                        : (materiaisAtivos
                                .where((m) => m.id == item.material!.id)
                                .firstOrNull ??
                            todosMateriais
                                .where((m) => m.id == item.material!.id)
                                .firstOrNull);

                    final int? fId = _itemFornecedorIds[idx];
                    final Fornecedor? fornecedorItemValue = fId == null
                        ? null
                        : fornecedores.where((f) => f.id == fId).firstOrNull;

                    // Ativos + o inativo atual (para não perder o value)
                    final List<MaterialModel> materiaisDropdown = [
                      ...materiaisAtivos,
                      if (item.material != null &&
                          item.material!.status == 'INATIVO' &&
                          !materiaisAtivos
                              .any((m) => m.id == item.material!.id))
                        item.material!,
                    ];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text('Item ${idx + 1}',
                                  style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary)),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 18, color: AppTheme.error),
                                onPressed: () => setState(() {
                                  item.dispose();
                                  _itens.removeAt(idx);
                                  final novo = <int, int?>{};
                                  _itemFornecedorIds.forEach((k, v) {
                                    if (k < idx) novo[k] = v;
                                    if (k > idx) novo[k - 1] = v;
                                  });
                                  _itemFornecedorIds
                                    ..clear()
                                    ..addAll(novo);
                                }),
                              ),
                            ]),
                            const SizedBox(height: 8),

                            // ✅ isExpanded: true + Text simples (sem Row dentro do item)
                            DropdownButtonFormField<MaterialModel?>(
                              initialValue: materialValue,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                  labelText: 'Material',
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.white),
                              items: [
                                const DropdownMenuItem<MaterialModel?>(
                                    value: null, child: Text('— Selecione —')),
                                ...materiaisDropdown.map((m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(
                                        _materialLabel(m),
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: m.status == 'INATIVO'
                                              ? AppTheme.error
                                              : null,
                                        ),
                                      ),
                                    )),
                              ],
                              onChanged: (v) =>
                                  setState(() => item.material = v),
                            ),
                            const SizedBox(height: 10),

                            if (item.material != null &&
                                item.material!.status == 'INATIVO')
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppTheme.error
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.warning_rounded,
                                      size: 14, color: AppTheme.error),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Material inativo: ${item.material!.nome}. Substitua por um material ativo.',
                                      style: GoogleFonts.nunito(
                                          fontSize: 11, color: AppTheme.error),
                                    ),
                                  ),
                                ]),
                              ),

                            DropdownButtonFormField<Fornecedor?>(
                              initialValue: fornecedorItemValue,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                  labelText: 'Fornecedor do item (opcional)',
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.white),
                              items: [
                                const DropdownMenuItem<Fornecedor?>(
                                    value: null, child: Text('— Nenhum —')),
                                ...fornecedores.map((f) => DropdownMenuItem(
                                      value: f,
                                      child: Text(f.nome,
                                          overflow: TextOverflow.ellipsis),
                                    )),
                              ],
                              onChanged: (v) => setState(
                                  () => _itemFornecedorIds[idx] = v?.id),
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
                                      border: Border.all(
                                          color: AppTheme.divider)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Preço Total',
                                          style: GoogleFonts.nunito(
                                              fontSize: 10,
                                              color: AppTheme.textHint)),
                                      Text(
                                          AppUtils.formatCurrency(
                                              item.precoTotal),
                                          style: GoogleFonts.nunito(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: AppTheme.primary)),
                                    ],
                                  ),
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
                          ],
                        ),
                      ),
                    );
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

                  if (_itens.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Total Geral:',
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(width: 12),
                          Text(AppUtils.formatCurrency(_totalGeral),
                              style: GoogleFonts.raleway(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: AppTheme.primary)),
                        ],
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 40),
            ],
          ),
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