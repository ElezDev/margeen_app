import 'package:flutter/material.dart';

import 'app_loading_indicator.dart';

class SearchPickerField<T> extends StatelessWidget {
  const SearchPickerField({
    super.key,
    required this.label,
    required this.hint,
    required this.selectedItem,
    required this.titleBuilder,
    required this.subtitleBuilder,
    required this.onPick,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final String hint;
  final T? selectedItem;
  final String Function(T item) titleBuilder;
  final String Function(T item) subtitleBuilder;
  final Future<T?> Function() onPick;
  final ValueChanged<T?> onChanged;
  final String? Function(T? value)? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormField<T>(
      initialValue: selectedItem,
      validator: validator,
      builder: (field) {
        final value = field.value;

        Future<void> openPicker() async {
          final picked = await onPick();
          field.didChange(picked);
          onChanged(picked);
        }

        void clear() {
          field.didChange(null);
          onChanged(null);
        }

        return InkWell(
          onTap: openPicker,
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: value != null
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: clear,
                    )
                  : const Icon(Icons.chevron_right),
              errorText: field.errorText,
            ),
            child: value == null
                ? Text(
                    hint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleBuilder(value as T),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitleBuilder(value as T),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

Future<T?> showSearchPickerSheet<T>({
  required BuildContext context,
  required String title,
  required String searchHint,
  required Future<List<T>> Function(String query) onSearch,
  required String Function(T item) titleBuilder,
  required String Function(T item) subtitleBuilder,
  IconData itemIcon = Icons.circle_outlined,
  int minQueryLength = 2,
  bool loadOnOpen = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _SearchPickerSheet<T>(
      title: title,
      searchHint: searchHint,
      onSearch: onSearch,
      titleBuilder: titleBuilder,
      subtitleBuilder: subtitleBuilder,
      itemIcon: itemIcon,
      minQueryLength: minQueryLength,
      loadOnOpen: loadOnOpen,
    ),
  );
}

class _SearchPickerSheet<T> extends StatefulWidget {
  const _SearchPickerSheet({
    required this.title,
    required this.searchHint,
    required this.onSearch,
    required this.titleBuilder,
    required this.subtitleBuilder,
    required this.itemIcon,
    this.minQueryLength = 2,
    this.loadOnOpen = false,
  });

  final String title;
  final String searchHint;
  final Future<List<T>> Function(String query) onSearch;
  final String Function(T item) titleBuilder;
  final String Function(T item) subtitleBuilder;
  final IconData itemIcon;
  final int minQueryLength;
  final bool loadOnOpen;

  @override
  State<_SearchPickerSheet<T>> createState() => _SearchPickerSheetState<T>();
}

class _SearchPickerSheetState<T> extends State<_SearchPickerSheet<T>> {
  final _controller = TextEditingController();
  List<T> _results = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.loadOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _search(''));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    final canSearchEmpty = widget.loadOnOpen && trimmed.isEmpty;

    if (trimmed.length < widget.minQueryLength && !canSearchEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await widget.onSearch(trimmed);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: widget.searchHint,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: _search,
                  ),
                ],
              ),
            ),
            Expanded(child: _buildResults(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    if (_isLoading) {
      return const AppLoadingPage();
    }

    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }

    if (_controller.text.trim().length < widget.minQueryLength &&
        !(widget.loadOnOpen && _controller.text.trim().isEmpty)) {
      return Center(
        child: Text(
          'Escribe al menos ${widget.minQueryLength} caracteres',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          widget.loadOnOpen && _controller.text.trim().isEmpty
              ? 'No hay elementos disponibles'
              : 'Sin resultados',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _results.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _results[index];
        return ListTile(
          leading: Icon(widget.itemIcon),
          title: Text(widget.titleBuilder(item)),
          subtitle: Text(widget.subtitleBuilder(item)),
          onTap: () => Navigator.pop(context, item),
        );
      },
    );
  }
}
