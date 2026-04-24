import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/historico_material_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/historico_material_model.dart';

class HistoricoEstoquePage extends StatefulWidget {
  const HistoricoEstoquePage({super.key});
  @override
  State<HistoricoEstoquePage> createState() => _HistoricoEstoquePageState();
}

class _HistoricoEstoquePageState extends State<HistoricoEstoquePage> {
  String? _filtroAcao;
  String _search = '';

  static const _acoes = [
    (label: 'Todos', valor: null),
    (label: 'Cadastro', valor: 'CADASTRO'),
    (label: 'Edição', valor: 'EDICAO'),
    (label: 'Inativado', valor: 'INATIVADO'),
    (label: 'Reativado', valor: 'REATIVADO'),
    (label: 'Saída', valor: 'SAIDA'),
    (label: 'Entrada', valor: 'ENTRADA'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoricoMaterialProvider>().carregar();
    });
  }

  List<HistoricoMaterial> _filtrar(List<HistoricoMaterial> all) {
    return all.where((h) {
      final nomeOk = _search.isEmpty ||
          (h.material?['nome'] as String? ?? '')
              .toLowerCase()
              .contains(_search.toLowerCase());
      return nomeOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HistoricoMaterialProvider>();
    final filtrado = _filtrar(prov.historico);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(children: [
        PageHeader(
          title: 'Histórico do Estoque',
          subtitle: 'Todas as ações realizadas nos materiais',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Atualizar',
              onPressed: () => prov.carregar(acao: _filtroAcao),
            ),
            const SizedBox(width: 8),
          ],
        ),

        // Barra de filtros
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: Row(children: [
            // Busca por material
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar material...',
                  prefixIcon: Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const SizedBox(width: 16),
            // Chips de filtro por ação
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _acoes.map((a) {
                  final selected = _filtroAcao == a.valor;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(a.label,
                          style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected ? Colors.white : AppTheme.textSecondary)),
                      selected: selected,
                      selectedColor: _acaoColor(a.valor),
                      backgroundColor: AppTheme.surfaceVariant,
                      checkmarkColor: Colors.white,
                      showCheckmark: false,
                      side: BorderSide(
                        color: selected
                            ? _acaoColor(a.valor)
                            : AppTheme.divider,
                      ),
                      onSelected: (_) {
                        setState(() => _filtroAcao = a.valor);
                        prov.carregar(acao: a.valor);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ]),
        ),
        const Divider(height: 1),

        // Contador
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(children: [
            Text('${filtrado.length} registro(s)',
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
        const Divider(height: 1),

        // Lista
        Expanded(
          child: prov.loading
              ? const LoadingWidget()
              : prov.error != null
                  ? ErrorWidget2(message: prov.error!, onRetry: () => prov.carregar())
                  : filtrado.isEmpty
                      ? const EmptyState(
                          icon: Icons.history_rounded,
                          title: 'Nenhum registro encontrado',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(24),
                          itemCount: filtrado.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: AppTheme.divider),
                          itemBuilder: (_, i) => _HistoricoTile(item: filtrado[i]),
                        ),
        ),
      ]),
    );
  }

  Color _acaoColor(String? acao) {
    switch (acao) {
      case 'CADASTRO': return AppTheme.primary;
      case 'EDICAO': return AppTheme.primaryDark;
      case 'INATIVADO': return AppTheme.error;
      case 'REATIVADO': return AppTheme.statusOk;
      case 'SAIDA': return AppTheme.statusBaixo;
      case 'ENTRADA': return AppTheme.statusOk;
      default: return AppTheme.textSecondary;
    }
  }
}

// ── Tile de cada registro ─────────────────────────────────────
class _HistoricoTile extends StatelessWidget {
  final HistoricoMaterial item;
  const _HistoricoTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final nomemat = (item.material?['nome'] as String?) ?? 'Material #${item.materialId}';
    final cfg = _acaoConfig(item.acao);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Ícone
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: cfg.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(cfg.icon, color: cfg.color, size: 18),
        ),
        const SizedBox(width: 14),

        // Conteúdo
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Linha 1: badge + nome do material
            Row(children: [
              _AcaoBadge(acao: item.acao, color: cfg.color, label: cfg.label),
              const SizedBox(width: 8),
              Expanded(
                child: Text(nomemat,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppTheme.textPrimary)),
              ),
            ]),
            const SizedBox(height: 4),

            // Observações
            if (item.observacoes != null && item.observacoes!.isNotEmpty)
              Text(item.observacoes!,
                  style: GoogleFonts.nunito(
                      fontSize: 12, color: AppTheme.textSecondary)),

            // Campos alterados (edição)
            if (item.camposAlterados != null &&
                item.camposAlterados!.isNotEmpty)
              _CamposAlterados(campos: item.camposAlterados!),
          ]),
        ),

        // Data/hora
        Text(
          AppUtils.formatDateTime(item.createdAt),
          style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textHint),
        ),
      ]),
    );
  }

  ({IconData icon, Color color, String label}) _acaoConfig(String acao) {
    switch (acao) {
      case 'CADASTRO':
        return (icon: Icons.add_circle_rounded, color: AppTheme.primary, label: 'Cadastro');
      case 'EDICAO':
        return (icon: Icons.edit_rounded, color: AppTheme.primaryDark, label: 'Edição');
      case 'INATIVADO':
        return (icon: Icons.block_rounded, color: AppTheme.error, label: 'Inativado');
      case 'REATIVADO':
        return (icon: Icons.check_circle_rounded, color: AppTheme.statusOk, label: 'Reativado');
      case 'SAIDA':
        return (icon: Icons.arrow_upward_rounded, color: AppTheme.statusBaixo, label: 'Saída');
      case 'ENTRADA':
        return (icon: Icons.arrow_downward_rounded, color: AppTheme.statusOk, label: 'Entrada');
      default:
        return (icon: Icons.info_rounded, color: AppTheme.textSecondary, label: acao);
    }
  }
}

// ── Badge colorido da ação ─────────────────────────────────────
class _AcaoBadge extends StatelessWidget {
  final String acao;
  final Color color;
  final String label;
  const _AcaoBadge({required this.acao, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: GoogleFonts.nunito(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ── Campos alterados na edição ─────────────────────────────────
class _CamposAlterados extends StatelessWidget {
  final Map<String, dynamic> campos;
  const _CamposAlterados({required this.campos});

  static const _labels = {
    'nome': 'Nome',
    'unidade': 'Unidade',
    'quantidadeAtual': 'Qtd. Atual',
    'estoqueInicial': 'Est. Inicial',
    'estoqueMinimo': 'Est. Mínimo',
    'custo': 'Custo',
    'ultimoValorPago': 'Último Valor Pago',
    'status': 'Status',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: campos.entries.map((e) {
          final campo = e.key;
          final label = _labels[campo] ?? campo;
          final de = e.value['de']?.toString() ?? '—';
          final para = e.value['para']?.toString() ?? '—';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('$label: ',
                  style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary)),
              Text(de,
                  style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: AppTheme.error,
                      decoration: TextDecoration.lineThrough)),
              const Text(' → ',
                  style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
              Text(para,
                  style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: AppTheme.statusOk,
                      fontWeight: FontWeight.w700)),
            ]),
          );
        }).toList(),
      ),
    );
  }
}