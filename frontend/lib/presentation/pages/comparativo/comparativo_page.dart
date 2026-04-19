import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/material_provider.dart';
import '../../providers/ordem_compra_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/material_model.dart';
import '../../../data/repositories/comparativo_repository.dart';

class ComparativoPage extends StatefulWidget {
  const ComparativoPage({super.key});
  @override
  State<ComparativoPage> createState() => _ComparativoPageState();
}

class _ComparativoPageState extends State<ComparativoPage> {
  final _repo = ComparativoRepository();
  MaterialModel? _materialSelecionado;
  Map<String, dynamic>? _resultado;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MaterialProvider>().carregarMateriais();
      context.read<OrdemCompraProvider>().carregarOrdens();
    });
  }

  Future<void> _buscar() async {
    if (_materialSelecionado == null) return;
    setState(() { _loading = true; _error = null; _resultado = null; });
    try {
      final r = await _repo.compararMaterial(_materialSelecionado!.id);
      setState(() { _resultado = r; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  /// Abre dialog para escolher qual OC em andamento receber o item
  Future<void> _adicionarAOC(Map<String, dynamic> fornecedor) async {
    if (_materialSelecionado == null) return;

    final prov = context.read<OrdemCompraProvider>();
    final ordensEmAndamento = prov.ordensEmAndamento;

    if (ordensEmAndamento.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma OC em andamento. Crie uma primeiro.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    // Dialog para selecionar a OC e preencher qtd/preço
    await showDialog(
      context: context,
      builder: (ctx) => _AdicionarAOCDialog(
        material: _materialSelecionado!,
        fornecedor: fornecedor,
        ordensEmAndamento: ordensEmAndamento,
        onConfirmar: (ordemId) async {
          final item = {
            'materialId': _materialSelecionado!.id,
            if (fornecedor['fornecedorId'] != null) 'fornecedorId': fornecedor['fornecedorId'],
            'quantidade': 1.0,
            'precoUnitario': (fornecedor['custo'] as num?)?.toDouble() ?? 0,
            if (fornecedor['prazoEntrega'] != null) 'prazoEntrega': fornecedor['prazoEntrega'],
          };

          final result = await prov.adicionarItem(ordemId, item);

          if (ctx.mounted) Navigator.pop(ctx);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result != null
                  ? 'Item adicionado à OC com sucesso!'
                  : prov.error ?? 'Erro ao adicionar item'),
              backgroundColor: result != null ? AppTheme.statusOk : AppTheme.error,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final materiais = context.watch<MaterialProvider>().materiais;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(children: [
        const PageHeader(
            title: 'Comparativo de Fornecedores',
            subtitle: 'Compare preços por material'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider)),
                child: Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<MaterialModel?>(
                      initialValue: materiais.where((m) => m.id == _materialSelecionado?.id).firstOrNull,
                      decoration: const InputDecoration(
                          labelText: 'Selecione o Material', isDense: true),
                      items: [
                        const DropdownMenuItem<MaterialModel?>(
                            value: null, child: Text('— Selecione —')),
                        ...materiais
                            .map<DropdownMenuItem<MaterialModel?>>((m) =>
                                DropdownMenuItem<MaterialModel?>(
                                    value: m, child: Text(m.nome)))
                            ,
                      ],
                      onChanged: (v) => setState(() {
                        _materialSelecionado = v;
                        _resultado = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                    label: const Text('Comparar'),
                    onPressed: _materialSelecionado == null || _loading ? null : _buscar,
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              if (_loading) const LoadingWidget(),
              if (_error != null) ErrorWidget2(message: _error!),
              if (_resultado != null)
                _ResultadoComparativo(
                  resultado: _resultado!,
                  onAdicionarAOC: _adicionarAOC,
                ),
              if (_resultado == null && !_loading && _error == null)
                const EmptyState(
                  icon: Icons.compare_arrows_rounded,
                  title: 'Selecione um material',
                  message:
                      'Escolha um material para ver a comparação de preços entre fornecedores.',
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─── Dialog ────────────────────────────────────────────────────────────────

class _AdicionarAOCDialog extends StatefulWidget {
  final MaterialModel material;
  final Map<String, dynamic> fornecedor;
  final List ordensEmAndamento;
  final Future<void> Function(int ordemId) onConfirmar;

  const _AdicionarAOCDialog({
    required this.material,
    required this.fornecedor,
    required this.ordensEmAndamento,
    required this.onConfirmar,
  });

  @override
  State<_AdicionarAOCDialog> createState() => _AdicionarAOCDialogState();
}

class _AdicionarAOCDialogState extends State<_AdicionarAOCDialog> {
  dynamic _ocSelecionada;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ocSelecionada = widget.ordensEmAndamento.first;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adicionar à OC',
          style: GoogleFonts.raleway(fontWeight: FontWeight.w700, fontSize: 17)),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Info material/fornecedor
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.inventory_2_rounded, size: 14, color: AppTheme.textHint),
                const SizedBox(width: 6),
                Text(widget.material.nome,
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.people_rounded, size: 14, color: AppTheme.textHint),
                const SizedBox(width: 6),
                Text(widget.fornecedor['fornecedorNome'] ?? '-',
                    style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
                const Spacer(),
                Text(
                  AppUtils.formatCurrency((widget.fornecedor['custo'] as num?)?.toDouble() ?? 0),
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.statusOk),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Selecionar OC
          Text('Ordem de Compra',
              style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          DropdownButtonFormField(
            initialValue: _ocSelecionada,
            decoration: const InputDecoration(isDense: true),
            items: widget.ordensEmAndamento
                .map((o) => DropdownMenuItem(
                      value: o,
                      child: Text('OC ${o.numeroOC}',
                          style: GoogleFonts.nunito(fontSize: 13)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _ocSelecionada = v),
          ),

        ]),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  await widget.onConfirmar(_ocSelecionada.id as int);
                  setState(() => _loading = false);
                },
          child: _loading
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Adicionar à OC'),
        ),
      ],
    );
  }
}

// ─── Resultado ─────────────────────────────────────────────────────────────

enum _OrdenarPor { preco, prazo }

class _ResultadoComparativo extends StatefulWidget {
  final Map<String, dynamic> resultado;
  final void Function(Map<String, dynamic>) onAdicionarAOC;

  const _ResultadoComparativo({required this.resultado, required this.onAdicionarAOC});

  @override
  State<_ResultadoComparativo> createState() => _ResultadoComparativoState();
}

class _ResultadoComparativoState extends State<_ResultadoComparativo> {
  _OrdenarPor _ordenarPor = _OrdenarPor.preco;

  List<Map<String, dynamic>> _ordenar(List<Map<String, dynamic>> lista) {
    final sorted = List<Map<String, dynamic>>.from(lista);
    if (_ordenarPor == _OrdenarPor.preco) {
      sorted.sort((a, b) => ((a['custo'] as num?) ?? 0).compareTo((b['custo'] as num?) ?? 0));
    } else {
      // Fornecedores sem prazo vão para o final
      sorted.sort((a, b) {
        final pA = a['prazoEntrega'] as int?;
        final pB = b['prazoEntrega'] as int?;
        if (pA == null && pB == null) return 0;
        if (pA == null) return 1;
        if (pB == null) return -1;
        return pA.compareTo(pB);
      });
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final raw = (widget.resultado['fornecedores'] as List?) ?? [];
    final fornecedores = _ordenar(raw.cast<Map<String, dynamic>>());

    // Destaques fixos (independente da ordenação)
    final melhorPreco = raw.cast<Map<String, dynamic>>()
        .where((f) => f['prazoEntrega'] != null)
        .toList()
      ..sort((a, b) => ((a['custo'] as num?) ?? 0).compareTo((b['custo'] as num?) ?? 0));
    final melhorPrazo = raw.cast<Map<String, dynamic>>()
        .where((f) => f['prazoEntrega'] != null)
        .toList()
      ..sort((a, b) => (a['prazoEntrega'] as int).compareTo(b['prazoEntrega'] as int));

    final destPreco = melhorPreco.isNotEmpty ? melhorPreco.first : null;
    final destPrazo = melhorPrazo.isNotEmpty ? melhorPrazo.first : null;
    // Só mostra destaque de prazo se for um fornecedor diferente do melhor preço
    final mostrarDestPrazo = destPrazo != null &&
        destPreco != null &&
        destPrazo['fornecedorId'] != destPreco['fornecedorId'];

    if (fornecedores.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline_rounded,
        title: 'Nenhum fornecedor vinculado',
        message: 'Este material não possui fornecedores com preço cadastrado.',
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Destaques ──
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Melhor preço
        if (destPreco != null)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.statusOk.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.statusOk.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: AppTheme.statusOk.withValues(alpha: 0.15),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.emoji_events_rounded, color: AppTheme.statusOk, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Menor Preço',
                      style: GoogleFonts.nunito(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                  Text(destPreco['fornecedorNome'] ?? '-',
                      style: GoogleFonts.raleway(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.statusOk),
                      overflow: TextOverflow.ellipsis),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(AppUtils.formatCurrency((destPreco['custo'] as num?)?.toDouble() ?? 0),
                      style: GoogleFonts.raleway(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.statusOk)),
                  if (destPreco['prazoEntrega'] != null)
                    Text(AppUtils.formatPrazo(destPreco['prazoEntrega']),
                        style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textHint)),
                ]),
              ]),
            ),
          ),
        // Melhor prazo (só se diferente do melhor preço)
        if (mostrarDestPrazo) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.timer_rounded, color: AppTheme.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Menor Prazo',
                      style: GoogleFonts.nunito(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                  Text(destPrazo['fornecedorNome'] ?? '-',
                      style: GoogleFonts.raleway(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.accent),
                      overflow: TextOverflow.ellipsis),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(AppUtils.formatPrazo(destPrazo['prazoEntrega']),
                      style: GoogleFonts.raleway(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.accent)),
                  Text(AppUtils.formatCurrency((destPrazo['custo'] as num?)?.toDouble() ?? 0),
                      style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textHint)),
                ]),
              ]),
            ),
          ),
        ],
      ]),
      const SizedBox(height: 20),

      // ── Ordenação ──
      Row(children: [
        Text('Ordenar por:',
            style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(width: 10),
        _SortChip(
          label: 'Menor Preço',
          icon: Icons.attach_money_rounded,
          selected: _ordenarPor == _OrdenarPor.preco,
          onTap: () => setState(() => _ordenarPor = _OrdenarPor.preco),
        ),
        const SizedBox(width: 8),
        _SortChip(
          label: 'Menor Prazo',
          icon: Icons.timer_rounded,
          selected: _ordenarPor == _OrdenarPor.prazo,
          onTap: () => setState(() => _ordenarPor = _OrdenarPor.prazo),
        ),
      ]),
      const SizedBox(height: 12),

      // ── Tabela ──
      Container(
        decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider)),
        child: Column(children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(children: [
              Expanded(flex: 3, child: Text('Fornecedor',
                  style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary))),
              Expanded(flex: 2, child: Row(children: [
                Text('Preço',
                    style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                if (_ordenarPor == _OrdenarPor.preco)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.arrow_upward_rounded, size: 11, color: AppTheme.primary),
                  ),
              ])),
              Expanded(flex: 2, child: Row(children: [
                Text('Prazo',
                    style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                if (_ordenarPor == _OrdenarPor.prazo)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.arrow_upward_rounded, size: 11, color: AppTheme.primary),
                  ),
              ])),
              const Expanded(flex: 3, child: SizedBox()),
            ]),
          ),

          // Linhas
          ...fornecedores.asMap().entries.map((e) {
            final i = e.key;
            final f = e.value;
            final isMelhorPreco = destPreco != null && f['fornecedorId'] == destPreco['fornecedorId'];
            final isMelhorPrazo = destPrazo != null && f['fornecedorId'] == destPrazo['fornecedorId'];
            return Column(children: [
              if (i != 0) const Divider(height: 1, color: AppTheme.divider),
              Container(
                color: isMelhorPreco
                    ? AppTheme.statusOk.withValues(alpha: 0.04)
                    : isMelhorPrazo
                        ? AppTheme.accent.withValues(alpha: 0.04)
                        : null,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  Expanded(flex: 3, child: Row(children: [
                    if (isMelhorPreco)
                      const Icon(Icons.star_rounded, color: AppTheme.statusOk, size: 14)
                    else if (isMelhorPrazo)
                      const Icon(Icons.timer_rounded, color: AppTheme.accent, size: 14),
                    if (isMelhorPreco || isMelhorPrazo) const SizedBox(width: 4),
                    Flexible(child: Text(f['fornecedorNome'] ?? '-',
                        style: GoogleFonts.nunito(
                            fontWeight: (isMelhorPreco || isMelhorPrazo) ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13))),
                  ])),
                  Expanded(flex: 2, child: Text(
                      AppUtils.formatCurrency((f['custo'] as num?)?.toDouble() ?? 0),
                      style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700, fontSize: 13,
                          color: isMelhorPreco ? AppTheme.statusOk : AppTheme.textPrimary))),
                  Expanded(flex: 2, child: Text(
                      AppUtils.formatPrazo(f['prazoEntrega']),
                      style: GoogleFonts.nunito(fontSize: 13,
                          color: isMelhorPrazo ? AppTheme.accent : AppTheme.textSecondary,
                          fontWeight: isMelhorPrazo ? FontWeight.w700 : FontWeight.w400))),
                  Expanded(flex: 3, child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isMelhorPreco)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppTheme.statusOk, borderRadius: BorderRadius.circular(10)),
                          child: Text('Menor Preço',
                              style: GoogleFonts.nunito(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                        )
                      else if (isMelhorPrazo)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(10)),
                          child: Text('Menor Prazo',
                              style: GoogleFonts.nunito(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Adicionar à uma OC em andamento',
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 13),
                          label: const Text('+ OC'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            textStyle: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => widget.onAdicionarAOC(f),
                        ),
                      ),
                    ],
                  )),
                ]),
              ),
            ]);
          }),
        ]),
      ),
    ]);
  }
}

// ─── Sort Chip ─────────────────────────────────────────────────────────────

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.divider),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: selected ? Colors.white : AppTheme.textSecondary),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppTheme.textSecondary)),
        ]),
      ),
    );
  }
}