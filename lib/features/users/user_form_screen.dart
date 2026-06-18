import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_provider.dart';
import '../../data/user_repository.dart';
import '../../shared/models/managed_user.dart';
import '../../shared/widgets/app_loading_indicator.dart';
import 'user_providers.dart';

class UserFormScreen extends ConsumerStatefulWidget {
  const UserFormScreen({super.key, this.userId});

  final int? userId;

  bool get isEditing => userId != null;

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _documentController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  String _role = 'vendedor';
  bool _isActive = true;
  bool _isSubmitting = false;
  bool _isDeactivating = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _documentController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populate(ManagedUser user) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = user.name;
    _emailController.text = user.email;
    _documentController.text = user.document ?? '';
    _phoneController.text = user.phone ?? '';
    _addressController.text = user.address ?? '';
    _notesController.text = user.notes ?? '';
    _role = user.primaryRole;
    _isActive = user.isActive;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      if (widget.isEditing) {
        await ref.read(userRepositoryProvider).update(
              widget.userId!,
              UpdateUserInput(
                name: _nameController.text.trim(),
                email: _emailController.text.trim(),
                password: _passwordController.text.isEmpty
                    ? null
                    : _passwordController.text,
                role: _role,
                document: _documentController.text.trim(),
                phone: _phoneController.text.trim(),
                address: _addressController.text.trim(),
                notes: _notesController.text.trim(),
                isActive: _isActive,
              ),
            );
        ref.invalidate(managedUserProvider(widget.userId!));
      } else {
        await ref.read(userRepositoryProvider).create(
              CreateUserInput(
                name: _nameController.text.trim(),
                email: _emailController.text.trim(),
                password: _passwordController.text,
                role: _role,
                document: _documentController.text.trim(),
                phone: _phoneController.text.trim(),
                address: _addressController.text.trim(),
                notes: _notesController.text.trim(),
                isActive: _isActive,
              ),
            );
      }

      ref.read(userListProvider.notifier).refresh();
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing ? 'Usuario actualizado.' : 'Usuario creado.',
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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar el usuario.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar usuario'),
        content: const Text(
          'El usuario no podrá iniciar sesión. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeactivating = true);

    try {
      await ref.read(userRepositoryProvider).deactivate(widget.userId!);
      ref.read(userListProvider.notifier).refresh();
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario desactivado.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeactivating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    if (widget.isEditing) {
      final userAsync = ref.watch(managedUserProvider(widget.userId!));

      return Scaffold(
        appBar: AppBar(title: const Text('Editar usuario')),
        body: userAsync.when(
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
                        ref.invalidate(managedUserProvider(widget.userId!)),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
          data: (user) {
            _populate(user);
            return _buildForm(
              context,
              theme,
              canDeactivate: currentUser?.id != user.id && user.isActive,
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo usuario')),
      body: _buildForm(context, theme, canDeactivate: false),
    );
  }

  Widget _buildForm(
    BuildContext context,
    ThemeData theme, {
    required bool canDeactivate,
  }) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresa el nombre';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresa el correo';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: widget.isEditing ? 'Nueva contraseña' : 'Contraseña',
              hintText: widget.isEditing ? 'Dejar vacío para no cambiar' : null,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
            ),
            validator: (value) {
              if (!widget.isEditing && (value == null || value.isEmpty)) {
                return 'Ingresa la contraseña';
              }
              if (value != null && value.isNotEmpty && value.length < 8) {
                return 'Mínimo 8 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: const InputDecoration(
              labelText: 'Rol',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'vendedor', child: Text('Vendedor')),
              DropdownMenuItem(value: 'admin', child: Text('Administrador')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _role = value);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _documentController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Documento',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Teléfono',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Dirección',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notas',
              border: OutlineInputBorder(),
            ),
          ),
          if (widget.isEditing) ...[
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Usuario activo'),
              subtitle: const Text('Puede iniciar sesión en la app'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: _isSubmitting
                ? const AppLoadingIndicator.small(
                    color: AppLoadingColor.onPrimary,
                  )
                : Text(widget.isEditing ? 'Guardar cambios' : 'Crear usuario'),
          ),
          if (canDeactivate) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isDeactivating ? null : _deactivate,
              icon: _isDeactivating
                  ? const AppLoadingIndicator.small()
                  : const Icon(Icons.person_off_outlined),
              label: const Text('Desactivar usuario'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
