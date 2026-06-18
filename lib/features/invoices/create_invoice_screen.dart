import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/client_repository.dart';
import '../../data/invoice_repository.dart';
import '../../data/product_repository.dart';
import '../../shared/models/client.dart';
import '../../shared/models/invoice.dart';
import '../../shared/models/product.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/app_loading_indicator.dart';
import '../../shared/widgets/margeen_card.dart';
import '../../shared/widgets/profit_banner.dart';
import '../../shared/widgets/search_picker_field.dart';
import 'invoice_providers.dart';

class _DraftLineItem {
  const _DraftLineItem({
    required this.input,
    required this.title,
    required this.subtitle,
  });

  final CreateInvoiceItemInput input;
  final String title;
  final String subtitle;

  num get lineTotal => input.quantity * input.unitPrice;
  num get lineProfit => input.quantity * (input.unitPrice - input.unitCost);
}

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
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
  final List<_DraftLineItem> _items = [];

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

  num get _subtotal =>
      _items.fold<num>(0, (sum, item) => sum + item.lineTotal);

  num get _previewTotal =>
      _subtotal - _parseNum(_discountController.text);

  num get _previewProfit =>
      _items.fold<num>(0, (sum, item) => sum + item.lineProfit);

  int get _previewMargin {
    if (_subtotal <= 0) return 0;
    return ((_previewProfit / _subtotal) * 100).round();
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
      searchHint: 'Filtrar por nombre (opcional)',
      itemIcon: Icons.inventory_2_outlined,
      loadOnOpen: true,
      minQueryLength: 0,
      onSearch: (q) => ref
          .read(productRepositoryProvider)
          .list(
            query: q.isEmpty ? null : q,
            activeOnly: true,
            perPage: 100,
          )
          .then((p) => p.data),
      titleBuilder: (p) => p.name,
      subtitleBuilder: (p) => '${p.unit} · ${formatCurrency(p.salePrice)}',
    );
  }

  String? _validateItemForm() {
    final qty = _parseNum(_quantityController.text);
    final price = _parseNum(_unitPriceController.text);
    final cost = _parseNum(_unitCostController.text);

    if (qty <= 0) return 'Ingresa una cantidad válida';
    if (price <= 0) return 'Ingresa el precio de venta';

    if (_useCatalogProduct) {
      if (_selectedProduct == null) return 'Selecciona un producto';
      if (cost <= 0) return 'Ingresa el costo unitario';
      return null;
    }

    final description = _manualDescriptionController.text.trim();
    final unit = _manualUnitController.text.trim();
    if (description.isEmpty) return 'Ingresa la descripción';
    if (unit.isEmpty) return 'Ingresa la unidad';
    if (cost < 0) return 'Costo inválido';

    return null;
  }

  _DraftLineItem? _buildDraftItem() {
    final error = _validateItemForm();
    if (error != null) return null;

    final qty = _parseNum(_quantityController.text);
    final price = _parseNum(_unitPriceController.text);
    final cost = _parseNum(_unitCostController.text);

    if (_useCatalogProduct && _selectedProduct != null) {
      final product = _selectedProduct!;
      return _DraftLineItem(
        input: CreateInvoiceItemInput(
          productId: product.id,
          quantity: qty,
          unitPrice: price,
          unitCost: cost,
        ),
        title: product.name,
        subtitle: '${product.unit} · ${qty.toString()} × ${formatCurrencyNum(price)}',
      );
    }

    final description = _manualDescriptionController.text.trim();
    final unit = _manualUnitController.text.trim();
    return _DraftLineItem(
      input: CreateInvoiceItemInput(
        description: description,
        unit: unit,
        quantity: qty,
        unitPrice: price,
        unitCost: cost,
      ),
      title: description,
      subtitle: '$unit · ${qty.toString()} × ${formatCurrencyNum(price)}',
    );
  }

  void _clearItemForm() {
    _selectedProduct = null;
    _quantityController.text = '1';
    _unitPriceController.clear();
    _unitCostController.clear();
    _manualDescriptionController.clear();
    _manualUnitController.text = 'unidad';
  }

  void _addItem() {
    final draft = _buildDraftItem();
    if (draft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_validateItemForm() ?? 'Completa el ítem')),
      );
      return;
    }

    setState(() {
      _items.add(draft);
      _clearItemForm();
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un cliente.')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un ítem a la factura.')),
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
      items: _items.map((e) => e.input).toList(),
    );

    try {
      final invoice = await ref.read(invoiceRepositoryProvider).create(input);
      ref.read(invoiceListProvider.notifier).refresh();
      if (mounted) {
        // Reemplaza "Nueva factura" para que al volver no quede el formulario.
        context.pushReplacement('/invoices/${invoice.id}');
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
          padding: const EdgeInsets.all(AppSpacing.page),
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
            if (_items.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.section),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ítems (${_items.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    formatCurrencyNum(_subtotal),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(_items.length, (index) {
                final item = _items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.card),
                  child: MargeenCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatCurrencyNum(item.lineTotal),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          tooltip: 'Quitar ítem',
                          onPressed: () => _removeItem(index),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: AppSpacing.section),
            Text(
              _items.isEmpty ? 'Agregar ítem' : 'Agregar otro ítem',
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
                hint: 'Toca para ver el catálogo',
                selectedItem: _selectedProduct,
                titleBuilder: (p) => p.name,
                subtitleBuilder: (p) =>
                    '${p.unit} · ${formatCurrency(p.salePrice)}',
                onPick: _pickProduct,
                onChanged: (product) => setState(() {
                  _selectedProduct = product;
                  if (product != null) _applyProductPrices(product);
                }),
              )
            else ...[
              TextFormField(
                controller: _manualDescriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _manualUnitController,
                decoration: const InputDecoration(labelText: 'Unidad'),
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
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unitPriceController,
                    keyboardType: TextInputType.number,
                    decoration: currencyInputDecoration(
                      labelText: 'Precio venta (COP)',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _unitCostController,
              keyboardType: TextInputType.number,
              decoration: currencyInputDecoration(
                labelText: 'Costo unitario (COP)',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add_rounded),
              label: Text(_items.isEmpty ? 'Agregar ítem' : 'Agregar otro ítem'),
            ),
            const SizedBox(height: AppSpacing.section),
            Text(
              'Totales',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              decoration: currencyInputDecoration(
                labelText: 'Descuento (COP)',
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
            if (_items.isNotEmpty && _previewTotal > 0)
              ProfitBanner(
                totalProfit: _previewProfit,
                marginPercent: _previewMargin,
              )
            else
              MargeenCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total estimado (COP)'),
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
                  ? const AppLoadingIndicator.small(
                      color: AppLoadingColor.onPrimary,
                    )
                  : Text(
                      _items.isEmpty
                          ? 'Crear factura'
                          : 'Crear factura (${_items.length} ítems)',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
