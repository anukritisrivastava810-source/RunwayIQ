import 'package:flutter_test/flutter_test.dart';
import 'package:runway_iq/main.dart';
import 'package:runway_iq/screens/splash_screen.dart';

void main() {
  testWidgets('App smoke test - starts with SplashScreen and transitions', (WidgetTester tester) async {
    await tester.pumpWidget(const RunwayIQApp());

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('RunwayIQ'), findsOneWidget);

    // Fast-forward past the splash screen timer
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
