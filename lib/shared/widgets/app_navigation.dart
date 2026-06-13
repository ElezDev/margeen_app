import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final rootScaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>(
  (ref) => GlobalKey<ScaffoldState>(),
);

void openAppDrawer(WidgetRef ref) {
  ref.read(rootScaffoldKeyProvider).currentState?.openDrawer();
}

class DrawerMenuButton extends ConsumerWidget {
  const DrawerMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () => openAppDrawer(ref),
      icon: const Icon(Icons.menu_rounded),
      tooltip: 'Menú',
    );
  }
}
