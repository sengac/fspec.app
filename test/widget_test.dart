import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fspec_mobile/app.dart';

void main() {
  testWidgets('Dashboard screen renders', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: FspecMobileApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify dashboard elements
    expect(find.text('fspec Mobile'), findsOneWidget);
    expect(find.text('No fspec instances connected'), findsOneWidget);
    expect(find.text('Add Connection'), findsWidgets); // Button in empty state and FAB
  });
}
