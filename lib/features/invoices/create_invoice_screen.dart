import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../data/client_repository.dart';
import '../../data/invoice_repository.dart';
import '../../data/product_repository.dart';
import '../../shared/models/client.dart';
import '../../shared/models/invoice.dart';
import '../../shared/models/product.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/margeen_card.dart';
import '../../shared/widgets/profit_banner.dart';
import '../../shared/widgets/search_picker_field.dart';
import 'invoice_providers.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '10');
  final _unitPriceController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  final _manualDescriptionController = TextEditingController();
  final _manualUnitController = TextEditingController(text: 'unidad');

  Client? _selectedClient;
  Product? _selectedProduct;
  bool _useCatalogProduct = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _unitCostController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    _manualDescriptionController.dispose();
    _manualUnitController.dispose();
    super.dispose();
  }

  num _parseNum(String value) => num.tryParse(value.trim()) ?? 0;

  void _applyProductPrices(Product product) {
    _unitPriceController.text = product.saleNum.toStringAsFixed(0);
    _unitCostController.text = product.costNum.toStringAsFixed(0);
  }

  num get _previewTotal {
    final qty = _parseNum(_quantityController.text);
    final price = _parseNum(_unitPriceController.text);
    final discount = _parseNum(_discountController.text);
    return (qty * price) - discount;
  }

  num get _previewProfit {
    final qty = _parseNum(_quantityController.text);
    final price = _parseNum(_unitPriceController.text);
    final cost = _parseNum(_unitCostController.text);
    return qty * (price - cost);
  }

  int get _previewMargin {
    final sales = _parseNum(_quantityController.text) *
        _parseNum(_unitPriceController.text);
    if (sales <= 0) return 0;
    return ((_previewProfit / sales) * 100).round();
  }

  Future<Client?> _pickClient() {
    return showSearchPickerSheet<Client>(
      context: context,
      title: 'Seleccionar cliente',
      searchHint: 'Nombre, documento o teléfono',
      itemIcon: Icons.person_outline,
      onSearch: (q) =>
          ref.read(clientRepositoryProvider).list(query: q).then((p) => p.data),
      titleBuilder: (c) => c.name,
      subtitleBuilder: (c) => c.subtitle,
    );
  }

  Future<Product?> _pickProduct() {
    return showSearchPickerSheet<Product>(
      context: context,
      title: 'Seleccionar producto',
      searchHint: 'Nombre del producto',
      itemIcon: Icons.inventory_2_outlined,
      onSearch: (q) => ref
          .read(productRepositoryProvider)
          .list(query: q, activeOnly: true)
          .then((p) => p.data),
      titleBuilder: (p) => p.name,
      subtitleBuilder: (p) => '${p.unit} · ${formatCurrency(p.salePrice)}',
    );
  }

  CreateInvoiceItemInput? _buildLineItem() {
    final qty = _parseNum(_quantityController.text);
    final price = _parseNum(_unitPriceController.text);
    final cost = _parseNum(_unitCostController.text);

    if (_useCatalogProduct) {
      if (_selectedProduct == null) return null;
      return CreateInvoiceItemInput(
        productId: _selectedProduct!.id,
        quantity: qty,
        unitPrice: price,
        unitCost: cost,
      );
    }

    final description = _manualDescriptionController.text.trim();
    final unit = _manualUnitController.text.trim();
    if (description.isEmpty || unit.isEmpty) return null;

    return CreateInvoiceItemInput(
      description: description,
      unit: unit,
      quantity: qty,
      unitPrice: price,
      unitCost: cost,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final lineItem = _buildLineItem();
    if (_selectedClient == null || lineItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa cliente y producto antes de crear.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final input = CreateInvoiceInput(
      clientId: _selectedClient!.id,
      discount: _parseNum(_discountController.text),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      items: [lineItem],
    );

    try {
      final invoice = await ref.read(invoiceRepositoryProvider).create(input);
      ref.read(invoiceListProvider.notifier).refresh();
      if (mounted) {
        context.push('/invoices/${invoice.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Factura creada.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva factura')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Cliente',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SearchPickerField<Client>(
              label: 'Cliente',
              hint: 'Buscar cliente',
              selectedItem: _selectedClient,
              titleBuilder: (c) => c.name,
              subtitleBuilder: (c) => c.subtitle,
              onPick: _pickClient,
              onChanged: (client) => setState(() => _selectedClient = client),
              validator: (v) => v == null ? 'Selecciona un cliente' : null,
            ),
            const SizedBox(height: 24),
            Text(
              'Producto',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Catálogo'),
                  icon: Icon(Icons.inventory_2_outlined),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Manual'),
                  icon: Icon(Icons.edit_outlined),
                ),
              ],
              selected: {_useCatalogProduct},
              onSelectionChanged: (s) => setState(() {
                _useCatalogProduct = s.first;
                _selectedProduct = null;
              }),
            ),
            const SizedBox(height: 12),
            if (_useCatalogProduct)
              SearchPickerField<Product>(
                label: 'Producto',
                hint: 'Buscar en catálogo',
                selectedItem: _selectedProduct,
                titleBuilder: (p) => p.name,
                subtitleBuilder: (p) =>
                    '${p.unit} · ${formatCurrency(p.salePrice)}',
                onPick: _pickProduct,
                onChanged: (product) => setState(() {
                  _selectedProduct = product;
                  if (product != null) _applyProductPrices(product);
                }),
                validator: (v) =>
                    _useCatalogProduct && v == null
                        ? 'Selecciona un producto'
                        : null,
              )
            else ...[
              TextFormField(
                controller: _manualDescriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _manualUnitController,
                decoration: const InputDecoration(labelText: 'Unidad'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                    onChanged: (_) => setState(() {}),
                    validator: (v) =>
                        _parseNum(v ?? '') <= 0 ? 'Inválida' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unitPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Precio venta',
                      prefixText: r'$ ',
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) =>
                        _parseNum(v ?? '') <= 0 ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _unitCostController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Costo unitario',
                prefixText: r'$ ',
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (_parseNum(v ?? '') < 0) return 'Inválido';
                if (_useCatalogProduct && _parseNum(v ?? '') <= 0) {
                  return 'Requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Descuento',
                prefixText: r'$ ',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notas'),
            ),
            const SizedBox(height: 20),
            if (_previewTotal > 0 && _parseNum(_unitPriceController.text) > 0)
              ProfitBanner(
                totalProfit: _previewProfit.toString(),
                marginPercent: _previewMargin,
              )
            else
              MargeenCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total estimado'),
                    Text(
                      formatCurrencyNum(_previewTotal),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Crear factura'),
            ),
          ],
        ),
      ),
    );
  }
}
