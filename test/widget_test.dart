import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sevktakip/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('opens without login and shows both work areas', (tester) async {
    await tester.pumpWidget(const SevkTakipApp());
    await tester.pumpAndSettle();

    expect(find.text('SEVKTAKİP'), findsOneWidget);
    expect(find.text('Mağaza'), findsOneWidget);
    expect(find.text('Depocu'), findsOneWidget);
  });

  testWidgets('depot area opens without login', (tester) async {
    await tester.pumpWidget(const SevkTakipApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Depocu'));
    await tester.pumpAndSettle();

    expect(find.text('Genel Bakış'), findsOneWidget);
    expect(find.text('Depo Stoku'), findsOneWidget);
    expect(find.text('Ürün ekle'), findsOneWidget);
  });
}
