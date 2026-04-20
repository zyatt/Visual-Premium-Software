import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/material_provider.dart';
import '../../providers/ordem_compra_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/repositories/comparativo_repository.dart';

class ComparativoPage extends StatefulWidget {
  const ComparativoPage({super.key});
  @override
  State<ComparativoPage> createState() => _ComparativoPageState();
}

class _ComparativoPageState extends State<ComparativoPage> {
  final _repo = ComparativoRepository();

  /// IDs dos materiais selecionados para comparação múltipla
  final Set<int> _selecionados = {};

  /// Resultados indexados por materialId
  List<Map<String, dynamic>> _resultados = [];
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
    if (_selecionados.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _resultados = [];
    });
    try {
      final lista = await _repo.compararMultiplosMateriais(_selecionados.toList());
      setState(() {
        _resultados = lista.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _adicionarAOC(
      Map<String, dynamic> fornecedor, int materialId) async {
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

    await showDialog(
      context: context,
      builder: (ctx) => _AdicionarAOCDialog(
        materialId: materialId,
        fornecedor: fornecedor,
        ordensEmAndamento: ordensEmAndamento,
        onConfirmar: (ordemId) async {
          final item = {
            'materialId': materialId,
            if (fornecedor['fornecedorId'] != null)
              'fornecedorId': fornecedor['fornecedorId'],
            'quantidade': 1.0,
            'precoUnitario':
                (fornecedor['custo'] as num?)?.toDouble() ?? 0,
            if (fornecedor['prazoEntrega'] != null)
              'prazoEntrega': fornecedor['prazoEntrega'],
          };

          final result = await prov.adicionarItem(ordemId, item);
          if (ctx.mounted) Navigator.pop(ctx);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result != null
                  ? 'Item adicionado à OC com sucesso!'
                  : prov.error ?? 'Erro ao adicionar item'),
              backgroundColor:
                  result != null ? AppTheme.statusOk : AppTheme.error,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final materiais = context
        .watch<MaterialProvider>()
        .materiais
        .where((m) => m.status != 'INATIVO')
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(children: [
        const PageHeader(
          title: 'Comparativo de Fornecedores',
          subtitle: 'Compare preços por material',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Painel de seleção múltipla ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.divider)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text('Selecionar Materiais',
                                style: GoogleFonts.raleway(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                            const Spacer(),
                            if (_selecionados.isNotEmpty)
                              TextButton(
                                onPressed: () =>
                                    setState(() => _selecionados.clear()),
                                child: const Text('Limpar seleção'),
                              ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.compare_arrows_rounded,
                                  size: 16),
                              label: Text(_selecionados.isEmpty
                                  ? 'Selecione ao menos 1'
                                  : 'Comparar (${_selecionados.length})'),
                              onPressed: _selecionados.isEmpty || _loading
                                  ? null
                                  : _buscar,
                            ),
                          ]),
                          const SizedBox(height: 12),
                          if (materiais.isEmpty)
                            Text('Nenhum material ativo disponível.',
                                style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color: AppTheme.textHint))
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: materiais.map((m) {
                                final sel = _selecionados.contains(m.id);
                                return FilterChip(
                                  label: Text(m.nome,
                                      style: GoogleFonts.nunito(
                                          fontSize: 12,
                                          fontWeight: sel
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: sel
                                              ? Colors.white
                                              : AppTheme.textPrimary)),
                                  selected: sel,
                                  onSelected: (_) => setState(() {
                                    if (sel) {
                                      _selecionados.remove(m.id);
                                    } else {
                                      _selecionados.add(m.id);
                                    }
                                  }),
                                  selectedColor: AppTheme.primary,
                                  checkmarkColor: Colors.white,
                                  backgroundColor: AppTheme.surfaceVariant,
                                  side: BorderSide(
                                    color: sel
                                        ? AppTheme.primary
                                        : AppTheme.divider,
                                  ),
                                  showCheckmark: true,
                                );
                              }).toList(),
                            ),
                        ]),
                  ),
                  const SizedBox(height: 24),

                  if (_loading) const LoadingWidget(),
                  if (_error != null) ErrorWidget2(message: _error!),

                  // ── Resultados ──
                  if (_resultados.isNotEmpty)
                    ..._resultados.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _ResultadoComparativo(
                            resultado: r,
                            onAdicionarAOC: (fornecedor) {
                              final mat = r['material'] as Map<String, dynamic>?;
                              final matId = mat?['id'] as int? ?? 0;
                              _adicionarAOC(fornecedor, matId);
                            },
                          ),
                        )),

                  if (_resultados.isEmpty && !_loading && _error == null)
                    const EmptyState(
                      icon: Icons.compare_arrows_rounded,
                      title: 'Selecione os materiais',
                      message:
                          'Marque um ou mais materiais acima e clique em "Comparar" para ver a comparação de preços entre fornecedores.',
                    ),
                ]),
          ),
        ),
      ]),
    );
  }
}

// ─── Dialog Adicionar à OC ──────────────────────────────────────────────────

class _AdicionarAOCDialog extends StatefulWidget {
  final int materialId;
  final Map<String, dynamic> fornecedor;
  final List ordensEmAndamento;
  final Future<void> Function(int ordemId) onConfirmar;

  const _AdicionarAOCDialog({
    required this.materialId,
    required this.fornecedor,
    required this.ordensEmAndamento,
    required this.onConfirmar,
  });

  @override
  State<_AdicionarAOCDialog> createState() => _AdicionarAOCDialogState();
}

class _AdicionarAOCDialogState extends State<_AdicionarAOCDialog> {
  int? _ordemSelecionadaId;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    if (widget.ordensEmAndamento.isNotEmpty) {
      _ordemSelecionadaId = widget.ordensEmAndamento.first.id as int;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('Adicionar à OC',
                    style: GoogleFonts.raleway(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
              const SizedBox(height: 4),
              Text(
                'Fornecedor: ${widget.fornecedor['fornecedorNome'] ?? '-'}  ·  ${AppUtils.formatCurrency((widget.fornecedor['custo'] as num?)?.toDouble() ?? 0)}',
                style: GoogleFonts.nunito(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _ordemSelecionadaId,
                decoration: const InputDecoration(
                    labelText: 'Ordem de Compra', isDense: true),
                items: widget.ordensEmAndamento
                    .map<DropdownMenuItem<int>>((o) => DropdownMenuItem(
                          value: o.id as int,
                          child: Text('OC ${o.numeroOC}',
                              style: GoogleFonts.nunito(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _ordemSelecionadaId = v),
              ),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: (_ordemSelecionadaId == null || _salvando)
                      ? null
                      : () async {
                          setState(() => _salvando = true);
                          await widget.onConfirmar(_ordemSelecionadaId!);
                          setState(() => _salvando = false);
                        },
                  child: _salvando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Adicionar'),
                ),
              ]),
            ]),
      ),
    );
  }
}

// ─── Resultado de um material ───────────────────────────────────────────────

enum _OrdenarPor { preco, prazo }

class _ResultadoComparativo extends StatefulWidget {
  final Map<String, dynamic> resultado;
  final void Function(Map<String, dynamic> fornecedor) onAdicionarAOC;

  const _ResultadoComparativo({
    required this.resultado,
    required this.onAdicionarAOC,
  });

  @override
  State<_ResultadoComparativo> createState() => _ResultadoComparativoState();
}

class _ResultadoComparativoState extends State<_ResultadoComparativo> {
  _OrdenarPor _ordenarPor = _OrdenarPor.preco;

  @override
  Widget build(BuildContext context) {
    final mat = widget.resultado['material'] as Map<String, dynamic>?;
    final matNome = (mat?['nome'] as String?) ?? 'Material';
    final rawFornecedores =
        (widget.resultado['fornecedores'] as List<dynamic>?) ?? [];
    final fornecedores =
        rawFornecedores.cast<Map<String, dynamic>>().toList();

    if (fornecedores.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(matNome,
              style: GoogleFonts.raleway(
                  fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text('Nenhum fornecedor vinculado a este material.',
              style: GoogleFonts.nunito(
                  fontSize: 13, color: AppTheme.textHint)),
        ]),
      );
    }

    // Destaque de menor preço e menor prazo
    final comPreco =
        fornecedores.where((f) => f['custo'] != null).toList();
    final comPrazo =
        fornecedores.where((f) => f['prazoEntrega'] != null).toList();
    final destPreco = comPreco.isNotEmpty
        ? (comPreco..sort((a, b) => (a['custo'] as num)
            .compareTo(b['custo'] as num)))
            .first
        : null;
    final destPrazo = comPrazo.isNotEmpty
        ? (comPrazo..sort((a, b) => (a['prazoEntrega'] as num)
            .compareTo(b['prazoEntrega'] as num)))
            .first
        : null;

    final sorted = [...fornecedores];
    if (_ordenarPor == _OrdenarPor.preco) {
      sorted.sort((a, b) =>
          ((a['custo'] as num?) ?? 999999)
              .compareTo((b['custo'] as num?) ?? 999999));
    } else {
      sorted.sort((a, b) =>
          ((a['prazoEntrega'] as num?) ?? 999999)
              .compareTo((b['prazoEntrega'] as num?) ?? 999999));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Título do material
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          const Icon(Icons.inventory_2_rounded,
              size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(matNome,
              style: GoogleFonts.raleway(
                  fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text('(${fornecedores.length} fornecedor${fornecedores.length != 1 ? 'es' : ''})',
              style: GoogleFonts.nunito(
                  fontSize: 12, color: AppTheme.textHint)),
        ]),
      ),

      // Cards de destaque
      if (destPreco != null || destPrazo != null)
        Row(children: [
          if (destPreco != null)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(right: 8, bottom: 12),
                decoration: BoxDecoration(
                    color: AppTheme.statusOk.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.statusOk.withValues(alpha: 0.3))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.star_rounded,
                            color: AppTheme.statusOk, size: 14),
                        const SizedBox(width: 4),
                        Text('Menor Preço',
                            style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.statusOk)),
                      ]),
                      const SizedBox(height: 4),
                      Text(destPreco['fornecedorNome'] ?? '-',
                          style: GoogleFonts.nunito(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      Text(
                          AppUtils.formatCurrency(
                              (destPreco['custo'] as num?)?.toDouble() ?? 0),
                          style: GoogleFonts.nunito(
                              fontSize: 11, color: AppTheme.textHint)),
                    ]),
              ),
            ),
          if (destPrazo != null)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(left: 0, bottom: 12),
                decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.accent.withValues(alpha: 0.3))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.timer_rounded,
                            color: AppTheme.accent, size: 14),
                        const SizedBox(width: 4),
                        Text('Menor Prazo',
                            style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.accent)),
                      ]),
                      const SizedBox(height: 4),
                      Text(destPrazo['fornecedorNome'] ?? '-',
                          style: GoogleFonts.nunito(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      Text(
                          AppUtils.formatCurrency(
                              (destPrazo['custo'] as num?)?.toDouble() ?? 0),
                          style: GoogleFonts.nunito(
                              fontSize: 11, color: AppTheme.textHint)),
                    ]),
              ),
            ),
        ]),

      // Ordenação
      Row(children: [
        Text('Ordenar por:',
            style: GoogleFonts.nunito(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600)),
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

      // Tabela
      Container(
        decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider)),
        child: Column(children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(children: [
              Expanded(
                  flex: 3,
                  child: Text('Fornecedor',
                      style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary))),
              Expanded(
                  flex: 2,
                  child: Row(children: [
                    Text('Preço',
                        style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary)),
                    if (_ordenarPor == _OrdenarPor.preco)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.arrow_upward_rounded,
                            size: 11, color: AppTheme.primary),
                      ),
                  ])),
              Expanded(
                  flex: 2,
                  child: Row(children: [
                    Text('Prazo',
                        style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary)),
                    if (_ordenarPor == _OrdenarPor.prazo)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.arrow_upward_rounded,
                            size: 11, color: AppTheme.primary),
                      ),
                  ])),
              const Expanded(flex: 3, child: SizedBox()),
            ]),
          ),
          ...sorted.asMap().entries.map((e) {
            final i = e.key;
            final f = e.value;
            final isMelhorPreco = destPreco != null &&
                f['fornecedorId'] == destPreco['fornecedorId'];
            final isMelhorPrazo = destPrazo != null &&
                f['fornecedorId'] == destPrazo['fornecedorId'];
            return Column(children: [
              if (i != 0)
                const Divider(height: 1, color: AppTheme.divider),
              Container(
                color: isMelhorPreco
                    ? AppTheme.statusOk.withValues(alpha: 0.04)
                    : isMelhorPrazo
                        ? AppTheme.accent.withValues(alpha: 0.04)
                        : null,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(children: [
                  Expanded(
                      flex: 3,
                      child: Row(children: [
                        if (isMelhorPreco)
                          const Icon(Icons.star_rounded,
                              color: AppTheme.statusOk, size: 14)
                        else if (isMelhorPrazo)
                          const Icon(Icons.timer_rounded,
                              color: AppTheme.accent, size: 14),
                        if (isMelhorPreco || isMelhorPrazo)
                          const SizedBox(width: 4),
                        Flexible(
                            child: Text(
                                f['fornecedorNome'] ?? '-',
                                style: GoogleFonts.nunito(
                                    fontWeight:
                                        (isMelhorPreco || isMelhorPrazo)
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                    fontSize: 13))),
                      ])),
                  Expanded(
                      flex: 2,
                      child: Text(
                          AppUtils.formatCurrency(
                              (f['custo'] as num?)?.toDouble() ?? 0),
                          style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isMelhorPreco
                                  ? AppTheme.statusOk
                                  : AppTheme.textPrimary))),
                  Expanded(
                      flex: 2,
                      child: Text(
                          AppUtils.formatPrazo(f['prazoEntrega']),
                          style: GoogleFonts.nunito(
                              fontSize: 13,
                              color: isMelhorPrazo
                                  ? AppTheme.accent
                                  : AppTheme.textSecondary,
                              fontWeight: isMelhorPrazo
                                  ? FontWeight.w700
                                  : FontWeight.w400))),
                  Expanded(
                      flex: 3,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isMelhorPreco)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: AppTheme.statusOk,
                                    borderRadius:
                                        BorderRadius.circular(10)),
                                child: Text('Menor Preço',
                                    style: GoogleFonts.nunito(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700)),
                              )
                            else if (isMelhorPrazo)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: AppTheme.accent,
                                    borderRadius:
                                        BorderRadius.circular(10)),
                                child: Text('Menor Prazo',
                                    style: GoogleFonts.nunito(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700)),
                              ),
                            const SizedBox(width: 8),
                            Tooltip(
                              message:
                                  'Adicionar à uma OC em andamento',
                              child: OutlinedButton.icon(
                                icon: const Icon(
                                    Icons.add_shopping_cart_rounded,
                                    size: 13),
                                label: const Text('+ OC'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  side: BorderSide(
                                      color: AppTheme.primary
                                          .withValues(alpha: 0.5)),
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                  textStyle: GoogleFonts.nunito(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () =>
                                    widget.onAdicionarAOC(f),
                              ),
                            ),
                          ])),
                ]),
              ),
            ]);
          }),
        ]),
      ),
    ]);
  }
}

// ─── Sort Chip ──────────────────────────────────────────────────────────────

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.divider),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 13,
              color: selected ? Colors.white : AppTheme.textSecondary),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : AppTheme.textSecondary)),
        ]),
      ),
    );
  }
}