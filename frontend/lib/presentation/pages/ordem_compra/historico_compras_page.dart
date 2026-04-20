import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/ordem_compra_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/historico_compra_model.dart';
import 'ordem_compra_detalhe_page.dart';

class HistoricoComprasPage extends StatefulWidget {
  const HistoricoComprasPage({super.key});

  @override
  State<HistoricoComprasPage> createState() => _HistoricoComprasPageState();
}

class _HistoricoComprasPageState extends State<HistoricoComprasPage> {
  DateTimeRange? _intervalo;
  String _busca = '';
  bool _carregado = false;

  final _ctrlInicio = TextEditingController();
  final _ctrlFim = TextEditingController();

  @override
  void initState() {
    super.initState();
    final hoje = DateTime.now();
    // FIX: usa meia-noite como início do dia
    final inicioDoHoje = DateTime(hoje.year, hoje.month, hoje.day);
    _intervalo = DateTimeRange(
      start: inicioDoHoje.subtract(const Duration(days: 30)),
      end: hoje,
    );
    _sincronizarControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  @override
  void dispose() {
    _ctrlInicio.dispose();
    _ctrlFim.dispose();
    super.dispose();
  }

  void _sincronizarControllers() {
    if (_intervalo != null) {
      _ctrlInicio.text = _formatInput(_intervalo!.start);
      _ctrlFim.text = _formatInput(_intervalo!.end);
    } else {
      _ctrlInicio.clear();
      _ctrlFim.clear();
    }
  }

  String _formatInput(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  DateTime? _parseInput(String v) {
    final parts = v.split('/');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    try {
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }

  Future<void> _carregar() async {
    setState(() => _carregado = false);
    await context.read<OrdemCompraProvider>().carregarHistorico(
          dataInicio: _intervalo?.start,
          dataFim: _intervalo?.end,
        );
    if (mounted) setState(() => _carregado = true);
  }

  // FIX: "Hoje" usa 00:00:00 do dia como início, não DateTime.now()
  void _aplicarAtalho(int dias) {
    final hoje = DateTime.now();
    final inicioDoHoje = DateTime(hoje.year, hoje.month, hoje.day);
    setState(() {
      _intervalo = DateTimeRange(
        start: dias == 0
            ? inicioDoHoje
            : inicioDoHoje.subtract(Duration(days: dias)),
        end: hoje,
      );
      _sincronizarControllers();
    });
    Navigator.of(context, rootNavigator: true).pop();
    _carregar();
  }

  void _aplicarCampos() {
    final ini = _parseInput(_ctrlInicio.text);
    final fim = _parseInput(_ctrlFim.text);
    if (ini != null && fim != null && !fim.isBefore(ini)) {
      setState(() => _intervalo = DateTimeRange(start: ini, end: fim));
      Navigator.of(context, rootNavigator: true).pop();
      _carregar();
    }
  }

  void _limparFiltro() {
    setState(() {
      _intervalo = null;
      _ctrlInicio.clear();
      _ctrlFim.clear();
    });
    Navigator.of(context, rootNavigator: true).pop();
    _carregar();
  }

  String get _labelIntervalo {
    if (_intervalo == null) return 'Todo o período';
    final ini = AppUtils.formatDate(_intervalo!.start);
    final fim = AppUtils.formatDate(_intervalo!.end);
    return '$ini → $fim';
  }

  void _abrirFiltro() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      builder: (ctx) => _FiltroDataDialog(
        intervalo: _intervalo,
        ctrlInicio: _ctrlInicio,
        ctrlFim: _ctrlFim,
        onAtalho: _aplicarAtalho,
        onAplicar: _aplicarCampos,
        onLimpar: _limparFiltro,
      ),
    );
  }

  List<HistoricoCompraEntry> _filtrar(List<HistoricoCompraEntry> lista) {
    if (_busca.isEmpty) return lista;
    final q = _busca.toLowerCase();
    return lista.where((e) {
      return e.materialNome.toLowerCase().contains(q) ||
          e.numeroOC.toString().contains(q) ||
          (e.fornecedorNome?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OrdemCompraProvider>();
    final historico = _filtrar(prov.historico);

    // ── Agrupa por OC ────────────────────────────────────────────
    final Map<int, List<HistoricoCompraEntry>> porOC = {};
    for (final e in historico) {
      porOC.putIfAbsent(e.ordemCompraId, () => []).add(e);
    }
    final gruposOC = porOC.entries.toList()
      ..sort((a, b) => b.value.first.data.compareTo(a.value.first.data));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          PageHeader(
            title: 'Histórico de Compras',
            subtitle: 'Movimentações de entrada por Ordem de Compra',
            actions: [
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range_rounded, size: 16),
                label: Text(_labelIntervalo),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.4)),
                  textStyle:
                      GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onPressed: _abrirFiltro,
              ),
              if (_intervalo != null) ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Limpar filtro de data',
                  onPressed: () {
                    setState(() {
                      _intervalo = null;
                      _ctrlInicio.clear();
                      _ctrlFim.clear();
                    });
                    _carregar();
                  },
                ),
              ],
              const SizedBox(width: 8),
            ],
          ),

          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar por material, nº OC ou fornecedor...',
                      prefixIcon: Icon(Icons.search_rounded, size: 18),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _busca = v),
                  ),
                ),
                const SizedBox(width: 16),
                _ResumoChip(
                  label: 'Entradas',
                  valor: historico.length.toString(),
                  cor: AppTheme.statusOk,
                ),
                const SizedBox(width: 8),
                _ResumoChip(
                  label: 'Total',
                  valor: AppUtils.formatCurrency(
                    historico.fold(0.0, (s, e) => s + e.custo * e.quantidade),
                  ),
                  cor: AppTheme.primary,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: prov.loadingHistorico || !_carregado
                ? const LoadingWidget()
                : historico.isEmpty
                    ? const EmptyState(
                        icon: Icons.history_rounded,
                        title: 'Nenhuma movimentação encontrada',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: gruposOC.length,
                        itemBuilder: (_, i) {
                          final grupo = gruposOC[i];
                          return _GrupoOC(
                            ordemCompraId: grupo.key,
                            entradas: grupo.value,
                            onVerOC: (ocId) => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrdemCompraDetalhePage(
                                    ordemCompraId: ocId),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog filtro de data
// ─────────────────────────────────────────────────────────────────────────────
class _FiltroDataDialog extends StatelessWidget {
  final DateTimeRange? intervalo;
  final TextEditingController ctrlInicio;
  final TextEditingController ctrlFim;
  final void Function(int dias) onAtalho;
  final VoidCallback onAplicar;
  final VoidCallback onLimpar;

  const _FiltroDataDialog({
    required this.intervalo,
    required this.ctrlInicio,
    required this.ctrlFim,
    required this.onAtalho,
    required this.onAplicar,
    required this.onLimpar,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 70, right: 24),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                  child: Row(
                    children: [
                      const Icon(Icons.tune_rounded,
                          size: 16, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Text('Filtrar por período',
                          style: GoogleFonts.raleway(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 28, minHeight: 28),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.divider),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Text('Atalhos rápidos',
                      style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textHint,
                          letterSpacing: 0.5)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _AtalhoChip(label: 'Hoje', onTap: () => onAtalho(0)),
                      _AtalhoChip(label: '7 dias', onTap: () => onAtalho(7)),
                      _AtalhoChip(label: '30 dias', onTap: () => onAtalho(30)),
                      _AtalhoChip(label: '3 meses', onTap: () => onAtalho(90)),
                      _AtalhoChip(label: '6 meses', onTap: () => onAtalho(180)),
                      _AtalhoChip(label: '1 ano', onTap: () => onAtalho(365)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppTheme.divider),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Text('Período personalizado',
                      style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textHint,
                          letterSpacing: 0.5)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                          child: _DataField(
                              label: 'De', controller: ctrlInicio)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('→',
                            style: TextStyle(color: AppTheme.textHint)),
                      ),
                      Expanded(
                          child:
                              _DataField(label: 'Até', controller: ctrlFim)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (intervalo != null)
                        TextButton(
                          onPressed: onLimpar,
                          style: TextButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary),
                          child: Text('Limpar',
                              style: GoogleFonts.nunito(fontSize: 13)),
                        ),
                      const Spacer(),
                      FilledButton(
                        onPressed: onAplicar,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Aplicar',
                            style: GoogleFonts.nunito(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AtalhoChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AtalhoChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
        child: Text(label,
            style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary)),
      ),
    );
  }
}

class _DataField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _DataField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                GoogleFonts.nunito(fontSize: 11, color: AppTheme.textHint)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: GoogleFonts.nunito(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'dd/mm/aaaa',
            hintStyle:
                GoogleFonts.nunito(fontSize: 12, color: AppTheme.textHint),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d/]')),
            LengthLimitingTextInputFormatter(10),
          ],
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip de resumo
// ─────────────────────────────────────────────────────────────────────────────
class _ResumoChip extends StatelessWidget {
  final String label;
  final String valor;
  final Color cor;
  const _ResumoChip(
      {required this.label, required this.valor, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(valor,
              style: GoogleFonts.raleway(
                  fontWeight: FontWeight.w700, fontSize: 14, color: cor)),
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grupo por Ordem de Compra
// ─────────────────────────────────────────────────────────────────────────────
class _GrupoOC extends StatelessWidget {
  final int ordemCompraId;
  final List<HistoricoCompraEntry> entradas;
  final void Function(int ocId) onVerOC;

  const _GrupoOC({
    required this.ordemCompraId,
    required this.entradas,
    required this.onVerOC,
  });

  @override
  Widget build(BuildContext context) {
    final primeiro = entradas.first;
    final totalOC =
        entradas.fold<double>(0, (s, e) => s + e.custo * e.quantidade);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabeçalho da OC (clicável) ───────────────────────
            InkWell(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              onTap: () => onVerOC(ordemCompraId),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_long_rounded,
                          size: 20, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OC ${primeiro.numeroOC}',
                            style: GoogleFonts.raleway(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 11, color: AppTheme.textHint),
                              const SizedBox(width: 4),
                              Text(AppUtils.formatDate(primeiro.data),
                                  style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary)),
                              if (primeiro.fornecedorNome != null) ...[
                                const SizedBox(width: 12),
                                const Icon(Icons.people_rounded,
                                    size: 11, color: AppTheme.textHint),
                                const SizedBox(width: 4),
                                Text(primeiro.fornecedorNome!,
                                    style: GoogleFonts.nunito(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppUtils.formatCurrency(totalOC),
                          style: GoogleFonts.raleway(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppTheme.primary),
                        ),
                        Text(
                          '${entradas.length} item(s)',
                          style: GoogleFonts.nunito(
                              fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppTheme.textHint),
                  ],
                ),
              ),
            ),

            // ── Itens da OC ──────────────────────────────────────
            const Divider(height: 1, color: AppTheme.divider),
            ...entradas.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              final isLast = i == entradas.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color:
                                AppTheme.statusOk.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.arrow_downward_rounded,
                              size: 14, color: AppTheme.statusOk),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.materialNome,
                                  style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              if (e.observacoes != null)
                                Text(e.observacoes!,
                                    style: GoogleFonts.nunito(
                                        fontSize: 11,
                                        color: AppTheme.textHint)),
                            ],
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '${AppUtils.formatNumber(e.quantidadeAntes)} → ${AppUtils.formatNumber(e.quantidadeDepois)}',
                                style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary),
                              ),
                              Text('estoque',
                                  style: GoogleFonts.nunito(
                                      fontSize: 10,
                                      color: AppTheme.textHint)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '+${AppUtils.formatNumber(e.quantidade)} un.',
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppTheme.statusOk),
                            ),
                            Text(
                              AppUtils.formatCurrency(
                                  e.custo * e.quantidade),
                              style: GoogleFonts.raleway(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppTheme.primary),
                            ),
                            Text(
                              '${AppUtils.formatCurrency(e.custo)}/un.',
                              style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      color: AppTheme.divider,
                      indent: 58,
                      endIndent: 16,
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}