import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_provider.dart';
import '../../data/product_repository.dart';
import '../../shared/models/product.dart';
import 'product_providers.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId});

  final int? productId;

  bool get isEditing => productId != null;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _costController = TextEditingController();
  final _saleController = TextEditingController();

  bool _isActive = true;
  bool _isSubmitting = false;
  bool _isDeleting = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _costController.dispose();
    _saleController.dispose();
    super.dispose();
  }

  void _populate(Product product) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = product.name;
    _unitController.text = product.unit;
    _costController.text = product.costNum.toStringAsFixed(0);
    _saleController.text = product.saleNum.toStringAsFixed(0);
    _isActive = product.isActive;
  }

  num _parseNum(String v) => num.tryParse(v.trim()) ?? 0;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      if (widget.isEditing) {
        await ref.read(productRepositoryProvider).update(
              widget.productId!,
              UpdateProductInput(
                name: _nameController.text.trim(),
                unit: _unitController.text.trim(),
                costPrice: _parseNum(_costController.text),
                salePrice: _parseNum(_saleController.text),
                isActive: _isActive,
              ),
            );
        ref.invalidate(productDetailProvider(widget.productId!));
      } else {
        await ref.read(productRepositoryProvider).create(
              CreateProductInput(
                name: _nameController.text.trim(),
                unit: _unitController.text.trim(),
                costPrice: _parseNum(_costController.text),
                salePrice: _parseNum(_saleController.text),
                isActive: _isActive,
              ),
            );
      }

      ref.read(productListProvider.notifier).refresh();
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing ? 'Producto actualizado.' : 'Producto creado.',
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text('¿Eliminar este producto del catálogo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(productRepositoryProvider).delete(widget.productId!);
      ref.read(productListProvider.notifier).refresh();
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto eliminado.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (widget.isEditing) {
      final productAsync = ref.watch(productDetailProvider(widget.productId!));
      return Scaffold(
        appBar: AppBar(title: const Text('Editar producto')),
        body: productAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (product) {
            _populate(product);
            return _buildForm(
              canDelete: user?.can('products.delete') ?? false,
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo producto')),
      body: _buildForm(canDelete: false),
    );
  }

  Widget _buildForm({required bool canDelete}) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _unitController,
            decoration: const InputDecoration(
              labelText: 'Unidad (arroba, bulto...)',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _costController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Precio costo',
              prefixText: r'$ ',
            ),
            validator: (v) => _parseNum(v ?? '') < 0 ? 'Inválido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _saleController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Precio venta',
              prefixText: r'$ ',
            ),
            validator: (v) {
              if (_parseNum(v ?? '') <= 0) return 'Requerido';
              return null;
            },
          ),
          if (widget.isEditing) ...[
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Producto activo'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.isEditing ? 'Guardar' : 'Crear producto'),
          ),
          if (canDelete) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isDeleting ? null : _delete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar producto'),
            ),
          ],
        ],
      ),
    );
  }
}
