import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/material_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/historico_model.dart';
import '../../../data/models/material_model.dart';

class HistoricoMaterialDialog extends StatefulWidget {
  final MaterialModel material;
  const HistoricoMaterialDialog({super.key, required this.material});
  @override
  State<HistoricoMaterialDialog> createState() => _HistoricoMaterialDialogState();
}

class _HistoricoMaterialDialogState extends State<HistoricoMaterialDialog> {
  List<HistoricoEstoque> _historico = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prov = context.read<MaterialProvider>();
    final h = await prov.buscarHistoricoMaterial(widget.material.id);
    if (mounted) setState(() { _historico = h; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 560,
        height: 540,
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Histórico: ${widget.material.nome}',
                style: GoogleFonts.raleway(fontSize: 17, fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 16),
          if (_loading)
            const Expanded(child: LoadingWidget())
          else if (_historico.isEmpty)
            const Expanded(child: EmptyState(icon: Icons.history_rounded, title: 'Nenhum histórico encontrado'))
          else
            Expanded(
              child: ListView.separated(
                itemCount: _historico.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.divider),
                itemBuilder: (_, i) {
                  final h = _historico[i];
                  final isEntrada = h.tipoMovimento == 'ENTRADA';
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: (isEntrada ? AppTheme.statusOk : AppTheme.statusCritico).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isEntrada ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: isEntrada ? AppTheme.statusOk : AppTheme.statusCritico,
                        size: 16,
                      ),
                    ),
                    title: Row(children: [
                      Text(isEntrada ? 'Entrada' : 'Saída',
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13,
                              color: isEntrada ? AppTheme.statusOk : AppTheme.statusCritico)),
                      const SizedBox(width: 8),
                      Text('+${AppUtils.formatNumber(h.quantidade)}',
                          style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${AppUtils.formatNumber(h.quantidadeAntes)} → ${AppUtils.formatNumber(h.quantidadeDepois)}',
                          style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
                      if (h.observacoes != null)
                        Text(h.observacoes!, style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textHint)),
                    ]),
                    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(AppUtils.formatDateTime(h.createdAt),
                          style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textHint)),
                      if (h.custo != null)
                        Text(AppUtils.formatCurrency(h.custo!),
                            style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  );
                },
              ),
            ),
        ]),
      ),
    );
  }
}