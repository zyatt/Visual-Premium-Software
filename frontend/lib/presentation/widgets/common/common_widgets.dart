import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

// ── Status Badge ──────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'OK':
        bg = AppTheme.statusOk.withValues(alpha: 0.12);
        fg = AppTheme.statusOk;
        label = 'Ok';
        break;
      case 'BAIXO':
        bg = AppTheme.statusBaixo.withValues(alpha: 0.12);
        fg = AppTheme.statusBaixo;
        label = 'Baixo';
        break;
      case 'CRITICO':
        bg = AppTheme.statusCritico.withValues(alpha: 0.12);
        fg = AppTheme.statusCritico;
        label = 'Crítico';
        break;
      case 'EM_ANDAMENTO':
        bg = AppTheme.primary.withValues(alpha: 0.10);
        fg = AppTheme.primary;
        label = 'Em Andamento';
        break;
      case 'FINALIZADO':
        bg = AppTheme.statusOk.withValues(alpha: 0.12);
        fg = AppTheme.statusOk;
        label = 'Finalizado';
        break;
      case 'CANCELADO':
        bg = AppTheme.statusCritico.withValues(alpha: 0.12);
        fg = AppTheme.statusCritico;
        label = 'Cancelado';
        break;
      default:
        bg = AppTheme.surfaceVariant;
        fg = AppTheme.textSecondary;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: GoogleFonts.nunito(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Page Header ───────────────────────────────────────────────
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.raleway(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    )),
                if (subtitle != null)
                  Text(subtitle!,
                      style: GoogleFonts.nunito(
                          fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: GoogleFonts.raleway(
                  fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
          if (subtitle != null)
            Text(subtitle!,
                style: GoogleFonts.nunito(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: AppTheme.textHint, size: 32),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.raleway(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.textHint)),
          ],
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

// ── Loading Overlay ───────────────────────────────────────────
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
}

// ── Error Widget ──────────────────────────────────────────────
class ErrorWidget2 extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorWidget2({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 48),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(color: AppTheme.textSecondary, fontSize: 14)),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Confirm Dialog ────────────────────────────────────────────
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  Color confirmColor = AppTheme.error,
}) =>
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message, style: GoogleFonts.nunito(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

// ── App Text Field ────────────────────────────────────────────
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool required;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffix;
  final Widget? prefix;
  final void Function(String)? onChanged;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.validator,
    this.required = false,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.suffix,
    this.prefix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      validator: validator ??
          (required
              ? (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null
              : null),
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        hintText: hint,
        suffixIcon: suffix,
        prefixIcon: prefix,
      ),
    );
  }
}