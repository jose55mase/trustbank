import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nitrado_server_manager/app.dart';

void main() {
  testWidgets('App renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: NitradoServerManagerApp(),
      ),
    );
    expect(find.text('Nitrado Server Manager'), findsOneWidget);
  });
}
