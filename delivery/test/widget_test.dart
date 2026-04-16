import 'package:flutter_test/flutter_test.dart';

import 'package:delivery_app/app.dart';

void main() {
  testWidgets('DeliveryApp renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppProviderScope(child: const DeliveryApp()),
    );
    await tester.pumpAndSettle();

    // The home screen placeholder should show 'Inicio' in the AppBar and body
    expect(find.text('Inicio'), findsWidgets);
  });
}
