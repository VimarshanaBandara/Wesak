import 'package:flutter_test/flutter_test.dart';
import 'package:wesak/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // App shell with bottom navigation render කරනවා
    await tester.pumpWidget(const WesakApp());
    await tester.pumpAndSettle();

    // Bottom nav destinations visible නේද check කරනවා
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
  });
}
