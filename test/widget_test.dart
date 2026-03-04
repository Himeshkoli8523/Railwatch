import 'package:cctv/app/app.dart';
import 'package:cctv/app/flavor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('shows login screen on app start', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CctvApp(flavor: AppFlavor.dev)),
    );

    await tester.pumpAndSettle();

    expect(find.text('CCTV Watch'), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
  });
}
