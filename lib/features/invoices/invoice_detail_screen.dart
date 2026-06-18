import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_provider.dart';
import '../../data/invoice_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/invoice.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/app_loading_indicator.dart';
import '../../shared/widgets/margeen_card.dart';
import '../../shared/widgets/profit_banner.dart';
import 'invoice_providers.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  final int invoiceId;

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  bool _isSharingPdf = false;
  bool _isCancelling = false;

  Future<void> _sharePdf(Invoice invoice) async {
    setState(() => _isSharingPdf = true);

    try {
      final bytes =
          await ref.read(invoiceRepositoryProvider).downloadPdf(invoice.id);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${invoice.number}.pdf');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Factura ${invoice.number}',
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo compartir el PDF.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharingPdf = false);
    }
  }

  Future<void> _cancelInvoice(Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anular factura'),
        content: Text(
          '¿Anular la factura ${invoice.number}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Anular'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);

    try {
      await ref.read(invoiceRepositoryProvider).cancel(invoice.id);
      ref.invalidate(invoiceDetailProvider(invoice.id));
      ref.read(invoiceListProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Factura anulada.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoiceAsync = ref.watch(invoiceDetailProvider(widget.invoiceId));
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(
        body: const AppLoadingPage(),
      );
    }

    final cancelAction = invoiceAsync.maybeWhen(
      data: (invoice) =>
          user.can('invoices.cancel') && invoice.canBeCancelled ? invoice : null,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: invoiceAsync.maybeWhen(
          data: (invoice) => Text(invoice.number),
          orElse: () => const Text('Factura'),
        ),
        actions: [
          if (cancelAction != null)
            IconButton(
              icon: _isCancelling
                  ? const AppLoadingIndicator.small()
                  : const Icon(Icons.cancel_outlined),
              tooltip: 'Anular',
              onPressed:
                  _isCancelling ? null : () => _cancelInvoice(cancelAction),
            ),
        ],
      ),
      body: invoiceAsync.when(
        loading: () => const AppLoadingPage(),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(invoiceDetailProvider(widget.invoiceId)),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (invoice) => _InvoiceDetailBody(
          invoice: invoice,
          theme: theme,
          isSharingPdf: _isSharingPdf,
          isCancelling: _isCancelling,
          canCancel: user.can('invoices.cancel') && invoice.canBeCancelled,
          onSharePdf: () => _sharePdf(invoice),
          onCancel: () => _cancelInvoice(invoice),
        ),
      ),
    );
  }
}

class _InvoiceDetailBody extends StatelessWidget {
  const _InvoiceDetailBody({
    required this.invoice,
    required this.theme,
    required this.isSharingPdf,
    required this.isCancelling,
    required this.canCancel,
    required this.onSharePdf,
    required this.onCancel,
  });

  final Invoice invoice;
  final ThemeData theme;
  final bool isSharingPdf;
  final bool isCancelling;
  final bool canCancel;
  final VoidCallback onSharePdf;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (invoice.isCancelled)
          MargeenCard(
            color: AppColors.error.withValues(alpha: 0.08),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.error),
                SizedBox(width: 8),
                Text(
                  'Esta factura fue anulada',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        if (invoice.isCancelled) const SizedBox(height: 12),
        ProfitBanner(
          totalProfit: parseAmount(invoice.totalProfit),
          marginPercent: invoice.profitMarginPercent,
        ),
        const SizedBox(height: 16),
        MargeenCard(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (invoice.client != null) ...[
                  _InfoRow(
                    label: 'Cliente',
                    value: invoice.client!.name,
                  ),
                  if (invoice.client!.phone != null)
                    _InfoRow(
                      label: 'Teléfono',
                      value: invoice.client!.phone!,
                    ),
                ],
                if (invoice.seller != null)
                  _InfoRow(label: 'Vendedor', value: invoice.seller!.name),
                if (invoice.issuedAt != null)
                  _InfoRow(
                    label: 'Fecha',
                    value: formatDateTime(invoice.issuedAt)!,
                  ),
                if (invoice.notes != null && invoice.notes!.isNotEmpty)
                  _InfoRow(label: 'Notas', value: invoice.notes!),
              ],
            ),
        ),
        const SizedBox(height: 16),
        Text(
          'Detalle',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        MargeenCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final item in invoice.items) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.description,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatQuantity(item.quantity)} ${item.unit} × ${formatCurrency(item.unitPrice)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ganancia: ${formatCurrency(item.lineProfit)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.profit,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            formatCurrency(item.lineTotal),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (item != invoice.items.last) const Divider(height: 1),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        MargeenCard(
          child: Column(
            children: [
              _TotalRow(
                label: 'Subtotal',
                value: formatCurrency(invoice.subtotal),
              ),
              if (parseAmount(invoice.discount) > 0)
                _TotalRow(
                  label: 'Descuento',
                  value: '- ${formatCurrency(invoice.discount)}',
                ),
              const Divider(),
              _TotalRow(
                label: 'Total',
                value: formatCurrency(invoice.total),
                bold: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (invoice.hasPdf)
          FilledButton.icon(
            onPressed: isSharingPdf ? null : onSharePdf,
            icon: isSharingPdf
                ? const AppLoadingIndicator.small(
                    color: AppLoadingColor.onPrimary,
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Compartir PDF'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        if (canCancel) ...[
          if (invoice.hasPdf) const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isCancelling ? null : onCancel,
            icon: isCancelling
                ? const AppLoadingIndicator.small()
                : const Icon(Icons.cancel_outlined),
            label: const Text('Anular factura'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 16 : 14,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
