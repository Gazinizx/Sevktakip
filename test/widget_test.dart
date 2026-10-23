import 'package:flutter_test/flutter_test.dart';
import 'package:sevktakip/main.dart';

void main() {
  testWidgets('Sevktakip opens without login and offers both work areas', (tester) async {
    await tester.pumpWidget(const SevkTakipApp());
    await tester.pumpAndSettle();
    expect(find.text('SEVKTAKİP'), findsOneWidget);
    expect(find.text('Mağaza'), findsOneWidget);
    expect(find.text('Depocu'), findsOneWidget);
    expect(find.textContaining('giriş'), findsNothing);
  });
}
