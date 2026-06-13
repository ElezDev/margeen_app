import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:margeen_app/main.dart';

void main() {
  testWidgets('App carga sin errores', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MargeenApp()));
    await tester.pump();
    expect(find.byType(MargeenApp), findsOneWidget);
  });
}
