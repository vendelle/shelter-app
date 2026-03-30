import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shelter_app/app.dart';

void main() {
  testWidgets('App renders Overview screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ShelterApp()),
    );

    // The app bar should show "Walk Overview"
    expect(find.text('Walk Overview'), findsOneWidget);

    // Bottom navigation should have all three tabs
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Planner'), findsOneWidget);
    expect(find.text('Walk Log'), findsOneWidget);
  });
}
